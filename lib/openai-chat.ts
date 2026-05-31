import type OpenAI from 'openai';

type ChatMessage = OpenAI.Chat.Completions.ChatCompletionMessageParam;

function isGpt5Model(model: string): boolean {
  return /^gpt-5(\.|$|-)/.test(model);
}

/**
 * GPT-5 models require max_completion_tokens instead of max_tokens.
 */
export function buildChatCompletionParams(
  model: string,
  messages: ChatMessage[],
  maxOutputTokens: number
): OpenAI.Chat.Completions.ChatCompletionCreateParamsNonStreaming {
  const params: OpenAI.Chat.Completions.ChatCompletionCreateParamsNonStreaming = {
    model,
    messages,
  };

  if (isGpt5Model(model)) {
    params.max_completion_tokens = maxOutputTokens;
  } else {
    params.max_tokens = maxOutputTokens;
    params.temperature = 0.8;
  }

  return params;
}
