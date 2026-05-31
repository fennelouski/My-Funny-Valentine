import OpenAI from 'openai';
import {
  GeneratedImageData,
  ImageOutputFormat,
  parseGeneratedImageResponse,
} from './image-host';
import { buildChatCompletionParams } from './openai-chat';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// GPT-5.x chat models (see https://developers.openai.com/api/docs/models)
const MODEL = process.env.OPENAI_MODEL || 'gpt-5-nano';
const FALLBACK_MODEL = process.env.OPENAI_FALLBACK_MODEL || 'gpt-5.4-nano';
const IMAGE_MODEL = process.env.OPENAI_IMAGE_MODEL || 'gpt-image-2';
const IMAGE_OUTPUT_FORMAT: ImageOutputFormat =
  process.env.OPENAI_IMAGE_FORMAT === 'png' ||
  process.env.OPENAI_IMAGE_FORMAT === 'webp'
    ? process.env.OPENAI_IMAGE_FORMAT
    : 'jpeg';

type ChatMessage = OpenAI.Chat.Completions.ChatCompletionMessageParam;

async function createChatCompletion(
  messages: ChatMessage[],
  maxOutputTokens: number
): Promise<OpenAI.Chat.Completions.ChatCompletion> {
  try {
    return await openai.chat.completions.create(
      buildChatCompletionParams(MODEL, messages, maxOutputTokens)
    );
  } catch (primaryError) {
    console.warn(`Primary model ${MODEL} failed, trying fallback:`, primaryError);
    return openai.chat.completions.create(
      buildChatCompletionParams(FALLBACK_MODEL, messages, maxOutputTokens)
    );
  }
}

function parseSayings(responseText: string): string[] {
  return responseText
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.match(/^\d+\./))
    .slice(0, 10);
}

/**
 * Generate 10 Valentine's sayings based on inspiration
 */
export async function generateSayings(inspiration: string): Promise<string[]> {
  const prompt = `Generate 10 unique Valentine's Day sayings based on this inspiration: "${inspiration}"

Requirements:
- Each saying should be romantic, heartfelt, or funny
- Keep sayings concise (under 100 characters each)
- Make them personal and creative
- Return only the sayings, one per line, no numbering

Sayings:`;

  try {
    const completion = await createChatCompletion(
      [
        {
          role: 'system',
          content:
            'You are a creative writer specializing in Valentine\'s Day messages. Generate unique, heartfelt sayings.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      500
    );

    const responseText = completion.choices[0]?.message?.content || '';
    const sayings = parseSayings(responseText);

    if (sayings.length < 10) {
      const additionalPrompt = `Generate ${10 - sayings.length} more unique Valentine's Day sayings based on: "${inspiration}". Return only the sayings, one per line.`;
      const additionalCompletion = await createChatCompletion(
        [
          {
            role: 'user',
            content: additionalPrompt,
          },
        ],
        300
      );

      const additionalText = additionalCompletion.choices[0]?.message?.content || '';
      sayings.push(...parseSayings(additionalText).slice(0, 10 - sayings.length));
    }

    return sayings.slice(0, 10);
  } catch (error) {
    console.error('OpenAI API error:', error);
    throw new Error('Failed to generate sayings');
  }
}

const STYLE_PROMPTS = {
  valentine:
    'Valentine\'s Day themed, romantic, hearts, red and pink colors, vivid colors and warm lighting',
  romantic: 'Romantic, soft, dreamy, warm colors, natural lighting',
  funny: 'Playful, humorous, lighthearted, colorful, vivid illustration style',
} as const;

/**
 * Generate an image using GPT Image models (returns base64 payload, not a URL).
 */
export async function generateImage(
  description: string,
  style: 'valentine' | 'romantic' | 'funny'
): Promise<GeneratedImageData> {
  const fullPrompt = `${description}. Style: ${STYLE_PROMPTS[style]}`;

  try {
    const response = await openai.images.generate({
      model: IMAGE_MODEL,
      prompt: fullPrompt,
      n: 1,
      size: '1024x1024',
      quality: 'medium',
      output_format: IMAGE_OUTPUT_FORMAT,
      output_compression: IMAGE_OUTPUT_FORMAT === 'jpeg' ? 85 : undefined,
    });

    return parseGeneratedImageResponse(response.data, IMAGE_OUTPUT_FORMAT);
  } catch (error) {
    console.error('OpenAI Image API error:', error);
    throw new Error('Failed to generate image');
  }
}

export {
  MODEL,
  FALLBACK_MODEL,
  IMAGE_MODEL,
  IMAGE_OUTPUT_FORMAT,
};
