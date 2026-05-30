import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Use gpt-oss-20b as primary (cheapest at $0.03/1M tokens)
// Fallback to gpt-5-nano if gpt-oss-20b unavailable
const MODEL = process.env.OPENAI_MODEL || 'gpt-oss-20b';
const FALLBACK_MODEL = 'gpt-5-nano';

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
    let completion;
    try {
      completion = await openai.chat.completions.create({
        model: MODEL,
        messages: [
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
        temperature: 0.8,
        max_tokens: 500,
      });
    } catch (primaryError) {
      // Fallback to gpt-5-nano if gpt-oss-20b fails
      console.warn(`Primary model ${MODEL} failed, trying fallback:`, primaryError);
      completion = await openai.chat.completions.create({
        model: FALLBACK_MODEL,
        messages: [
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
        temperature: 0.8,
        max_tokens: 500,
      });
    }

    const responseText = completion.choices[0]?.message?.content || '';
    const sayings = responseText
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 0 && !line.match(/^\d+\./)) // Remove numbering
      .slice(0, 10); // Ensure exactly 10

    // If we don't have 10 sayings, pad with generated ones
    if (sayings.length < 10) {
      const additionalPrompt = `Generate ${10 - sayings.length} more unique Valentine's Day sayings based on: "${inspiration}". Return only the sayings, one per line.`;
      let additionalCompletion;
      try {
        additionalCompletion = await openai.chat.completions.create({
          model: MODEL,
          messages: [
            {
              role: 'user',
              content: additionalPrompt,
            },
          ],
          temperature: 0.8,
          max_tokens: 300,
        });
      } catch (primaryError) {
        // Fallback to gpt-5-nano if gpt-oss-20b fails
        additionalCompletion = await openai.chat.completions.create({
          model: FALLBACK_MODEL,
          messages: [
            {
              role: 'user',
              content: additionalPrompt,
            },
          ],
          temperature: 0.8,
          max_tokens: 300,
        });
      }

      const additionalText = additionalCompletion.choices[0]?.message?.content || '';
      const additionalSayings = additionalText
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line.length > 0 && !line.match(/^\d+\./))
        .slice(0, 10 - sayings.length);

      sayings.push(...additionalSayings);
    }

    return sayings.slice(0, 10); // Ensure exactly 10
  } catch (error) {
    console.error('OpenAI API error:', error);
    throw new Error('Failed to generate sayings');
  }
}

/**
 * Generate an image using DALL-E
 */
export async function generateImage(
  description: string,
  style: 'valentine' | 'romantic' | 'funny'
): Promise<string> {
  const stylePrompt = {
    valentine: 'Valentine\'s Day themed, romantic, hearts, red and pink colors',
    romantic: 'Romantic, soft, dreamy, warm colors',
    funny: 'Playful, humorous, lighthearted, colorful',
  };

  const fullPrompt = `${description}. Style: ${stylePrompt[style]}`;

  try {
    // Use gpt-image-1.5 for image generation (dall-e-3 was shut down May 12, 2026)
    const response = await openai.images.generate({
      model: 'gpt-image-1.5',
      prompt: fullPrompt,
      n: 1,
      size: '1024x1024',
    });

    const imageUrl = response.data[0]?.url;
    if (!imageUrl) {
      throw new Error('No image URL returned from OpenAI');
    }

    return imageUrl;
  } catch (error) {
    console.error('OpenAI Image API error:', error);
    throw new Error('Failed to generate image');
  }
}
