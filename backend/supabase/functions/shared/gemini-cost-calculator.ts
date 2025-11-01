/**
 * Gemini Cost Calculator
 * Calculates costs based on official Google Gemini API pricing
 * Updated: 2025-10-31
 * 
 * Current pricing (per 1M tokens):
 * - Gemini 1.5 Flash: $0.075 input, $0.30 output
 * - Gemini 1.5 Pro: $1.25 input, $5.00 output
 */

export type GeminiModel = 'gemini-1.5-flash' | 'gemini-1.5-pro';

interface ModelPricing {
  input: number;  // Cost per 1M input tokens
  output: number; // Cost per 1M output tokens
}

interface CostCalculation {
  inputCost: number;
  outputCost: number;
  totalCost: number;
  model: GeminiModel;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
}

interface UsageMetrics {
  user_id: string;
  conversation_id: string;
  message_id: string;
  model_used: GeminiModel;
  tokens_input: number;
  tokens_output: number;
  cost_input_usd: number;
  cost_output_usd: number;
  request_duration_ms: number;
  files_processed: number;
  request_type?: string;
  error_occurred?: boolean;
  error_message?: string;
}

// Official Gemini API pricing (as of October 2025)
const GEMINI_PRICING: Record<GeminiModel, ModelPricing> = {
  'gemini-1.5-flash': {
    input: 0.075,   // $0.075 per 1M tokens
    output: 0.30    // $0.30 per 1M tokens
  },
  'gemini-1.5-pro': {
    input: 1.25,    // $1.25 per 1M tokens
    output: 5.00    // $5.00 per 1M tokens
  }
};

/**
 * Calculate costs for a Gemini API request
 */
export const calculateGeminiCosts = (
  model: GeminiModel,
  inputTokens: number,
  outputTokens: number
): CostCalculation => {
  const pricing = GEMINI_PRICING[model];
  
  if (!pricing) {
    throw new Error(`Unknown model: ${model}`);
  }

  if (inputTokens < 0 || outputTokens < 0) {
    throw new Error('Token counts must be non-negative');
  }

  // Calculate costs (pricing is per 1M tokens)
  const inputCost = (inputTokens / 1_000_000) * pricing.input;
  const outputCost = (outputTokens / 1_000_000) * pricing.output;
  const totalCost = inputCost + outputCost;

  return {
    inputCost: parseFloat(inputCost.toFixed(6)),
    outputCost: parseFloat(outputCost.toFixed(6)),
    totalCost: parseFloat(totalCost.toFixed(6)),
    model,
    inputTokens,
    outputTokens,
    totalTokens: inputTokens + outputTokens
  };
};

/**
 * Get cost estimate for a request before sending
 */
export const estimateCosts = (
  model: GeminiModel,
  estimatedInputTokens: number,
  estimatedOutputTokens: number = 1000 // Default assumption
): CostCalculation => {
  return calculateGeminiCosts(model, estimatedInputTokens, estimatedOutputTokens);
};

/**
 * Get the most cost-effective model for a given use case
 */
export const getOptimalModel = (
  inputTokens: number,
  expectedOutputTokens: number,
  qualityPriority: 'cost' | 'quality' = 'cost'
): GeminiModel => {
  const flashCost = calculateGeminiCosts('gemini-1.5-flash', inputTokens, expectedOutputTokens);
  const proCost = calculateGeminiCosts('gemini-1.5-pro', inputTokens, expectedOutputTokens);

  // If quality is priority and cost difference is reasonable (< 10x), use Pro
  if (qualityPriority === 'quality' && proCost.totalCost < (flashCost.totalCost * 10)) {
    return 'gemini-1.5-pro';
  }

  // Otherwise, use Flash for cost optimization
  return 'gemini-1.5-flash';
};

/**
 * Create metrics object for database insertion
 */
export const createUsageMetrics = (
  baseData: {
    user_id: string;
    conversation_id: string;
    message_id: string;
    request_duration_ms: number;
    files_processed?: number;
    request_type?: string;
  },
  costs: CostCalculation,
  error?: { occurred: boolean; message?: string }
): UsageMetrics => {
  return {
    user_id: baseData.user_id,
    conversation_id: baseData.conversation_id,
    message_id: baseData.message_id,
    model_used: costs.model,
    tokens_input: costs.inputTokens,
    tokens_output: costs.outputTokens,
    cost_input_usd: costs.inputCost,
    cost_output_usd: costs.outputCost,
    request_duration_ms: baseData.request_duration_ms,
    files_processed: baseData.files_processed || 0,
    request_type: baseData.request_type || 'chat',
    error_occurred: error?.occurred || false,
    error_message: error?.message || undefined
  };
};

/**
 * Cost-related utility functions
 */
export const CostUtils = {
  /**
   * Format cost as currency string
   */
  formatCost: (cost: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 6,
      maximumFractionDigits: 6
    }).format(cost);
  },

  /**
   * Calculate cost per message
   */
  getCostPerMessage: (totalCost: number, messageCount: number): number => {
    if (messageCount === 0) return 0;
    return parseFloat((totalCost / messageCount).toFixed(6));
  },

  /**
   * Calculate daily budget usage percentage
   */
  getBudgetUsage: (currentSpending: number, dailyBudget: number): number => {
    if (dailyBudget === 0) return 0;
    return parseFloat(((currentSpending / dailyBudget) * 100).toFixed(2));
  },

  /**
   * Estimate monthly cost based on current daily spending
   */
  estimateMonthlyCost: (dailySpending: number, daysInMonth: number = 30): number => {
    return parseFloat((dailySpending * daysInMonth).toFixed(2));
  },

  /**
   * Check if spending is above threshold
   */
  isSpendingHigh: (currentCost: number, threshold: number): boolean => {
    return currentCost >= threshold;
  }
};

/**
 * Predefined cost thresholds for alerts
 */
export const COST_THRESHOLDS = {
  DAILY: {
    LOW: 1.00,      // $1/day - warning level
    MEDIUM: 5.00,   // $5/day - concern level  
    HIGH: 10.00     // $10/day - limit level
  },
  MONTHLY: {
    LOW: 30.00,     // $30/month - warning level
    MEDIUM: 150.00, // $150/month - concern level
    HIGH: 300.00    // $300/month - limit level
  },
  PER_USER_DAILY: {
    LOW: 0.50,      // $0.50/user/day
    MEDIUM: 2.00,   // $2.00/user/day
    HIGH: 5.00      // $5.00/user/day
  }
};

/**
 * Performance benchmarks for optimization
 */
export const PERFORMANCE_BENCHMARKS = {
  COST_PER_1K_TOKENS: {
    FLASH: 0.000375,  // Average cost per 1K tokens for Flash
    PRO: 0.003125     // Average cost per 1K tokens for Pro
  },
  ACCEPTABLE_RESPONSE_TIME: 5000, // 5 seconds
  MAX_TOKENS_PER_REQUEST: 32000,  // Gemini limit
  RECOMMENDED_TOKENS_PER_REQUEST: 8000 // For cost optimization
};

export default {
  calculateGeminiCosts,
  estimateCosts,
  getOptimalModel,
  createUsageMetrics,
  CostUtils,
  COST_THRESHOLDS,
  PERFORMANCE_BENCHMARKS
};