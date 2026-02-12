# Prompt 07: Sharing and Export Features

## Objective
Implement sharing to social media platforms and export functionality including macOS GIF export.

## Context
Users need to share their cards on Instagram, Facebook, TikTok, and export as GIFs on macOS.

## Reference Documentation
- `docs/07-EXPORT-SHARING.md` - Complete sharing requirements
- `docs/10-TECHNICAL-SPECS.md` - Technical specs

## Tasks

### 1. Implement iOS Share Sheet
- Use UIActivityViewController
- Include card image in share items
- Support all standard destinations
- Handle share completion
- Support multiple formats (image, PDF)

### 2. Implement Instagram Sharing
- Optimize image for Instagram (1080x1080 or 1080x1350)
- Format as JPEG/PNG
- High quality (90%+)
- Handle Instagram app not installed
- Support Stories and Feed

### 3. Implement Facebook Sharing
- Optimize image for Facebook (1200x630 or original)
- Format as JPEG
- Handle Facebook app not installed
- Support web fallback

### 4. Implement TikTok Sharing
- Optimize for TikTok (1080x1920 vertical)
- Format as JPEG or MP4
- Handle TikTok app not installed
- Support video format option

### 5. Implement Save to Photos
- Save card image to Photos library
- Request photo library permission
- Handle permission denied
- Show success confirmation
- Support album creation

### 6. Implement macOS GIF Export
- Detect macOS platform
- Create animated GIF from card
- Support animation options:
  - Fade in/out
  - Slide
  - Zoom
  - Heart animation
  - Text reveal
- Optimize GIF (10-15 fps, 256 colors)
- File dialog for save location
- Limit file size (<10MB)

### 7. Create Share Preview
- Preview screen before sharing
- Show card preview
- Quick edit option
- Format selection
- Destination selection
- Cancel option

### 8. Implement Image Optimization
- Detect sharing destination
- Apply appropriate compression
- Maintain aspect ratio
- Preserve quality where needed
- Different settings for different platforms

## Deliverables
- Complete iOS share sheet integration
- Instagram sharing optimized
- Facebook sharing optimized
- TikTok sharing optimized
- Save to Photos functionality
- macOS GIF export with animations
- Share preview screen
- Image optimization system

## Notes
- Optimize images for each platform
- Handle app not installed gracefully
- Support all standard share destinations
- High quality for social media
- Efficient GIF generation
- Clear user feedback
