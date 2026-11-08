#!/usr/bin/env python3
"""
Batch video captioning using Captions.ai (Mirage API)
Processes all videos in a folder and saves captioned versions
"""

import os
import sys
import time
import requests
from pathlib import Path

API_KEY = "sk-t1uewRgDVBEnuHBL8oz2D64Vg1pNldbbCd32VK9yAGw"
API_BASE = "https://api.mirage.app/v1"

INPUT_DIR = "/Volumes/T7"
OUTPUT_DIR = "/Volumes/T7/captioned"

HEADERS = {
    "x-api-key": API_KEY
}

def get_video_files():
    """Get exercise video files from input directory (proper naming convention)"""
    import re
    video_extensions = {'.mp4', '.mov', '.avi', '.mkv'}
    # Match exercise naming: XX_XX_NAME_TYPE.mp4 (e.g., HP_AB_STANDING_HIPABAD_MOB.mp4)
    exercise_pattern = re.compile(r'^[A-Z]{2}_')

    videos = []
    for f in Path(INPUT_DIR).iterdir():
        if (f.suffix.lower() in video_extensions
            and f.stat().st_size > 0
            and exercise_pattern.match(f.name)):
            videos.append(f)
    return sorted(videos)

def list_caption_templates():
    """Get available caption templates"""
    print("Fetching available caption templates...")
    response = requests.get(
        f"{API_BASE}/videos/captions/templates",
        headers=HEADERS
    )
    if response.status_code == 200:
        templates = response.json()
        print(f"Found {len(templates.get('templates', []))} templates")
        return templates
    else:
        print(f"Error fetching templates: {response.status_code}")
        return None

def add_captions(video_path, template_id=None):
    """Upload video and add captions"""
    print(f"  Uploading {video_path.name}...")

    with open(video_path, 'rb') as f:
        files = {'video': (video_path.name, f, 'video/mp4')}
        data = {}
        if template_id:
            data['caption_template_id'] = template_id

        response = requests.post(
            f"{API_BASE}/videos/captions",
            headers=HEADERS,
            files=files,
            data=data
        )

    if response.status_code not in [200, 201, 202]:
        print(f"  Error: {response.status_code} - {response.text}")
        return None

    result = response.json()
    print(f"  Response: {result}")
    return result

def check_video_status(video_id):
    """Check status of video processing"""
    response = requests.get(
        f"{API_BASE}/videos/{video_id}",
        headers=HEADERS
    )
    if response.status_code == 200:
        return response.json()
    return None

def download_video(url, output_path):
    """Download captioned video"""
    print(f"  Downloading to {output_path.name}...")
    response = requests.get(url, stream=True)

    with open(output_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

    print(f"  Downloaded: {output_path.stat().st_size / (1024*1024):.1f} MB")
    return True

def process_video(video_path, output_dir, template_id=None):
    """Process a single video through the captioning pipeline"""
    output_path = output_dir / f"{video_path.stem}_captioned.mp4"

    if output_path.exists():
        print(f"  Skipping (already exists): {output_path.name}")
        return True

    # Upload and start captioning
    result = add_captions(video_path, template_id)
    if not result:
        return False

    # Get video ID or download URL from response
    video_id = result.get('video_id') or result.get('id')
    download_url = result.get('video_url') or result.get('url') or result.get('output_url')

    # If we have a direct download URL, use it
    if download_url:
        download_video(download_url, output_path)
        return True

    # Otherwise poll for completion
    if video_id:
        print(f"  Job ID: {video_id}")
        max_attempts = 60  # 10 minutes max

        for attempt in range(max_attempts):
            time.sleep(10)
            status_data = check_video_status(video_id)

            if status_data:
                status = status_data.get('status', 'unknown')
                print(f"  Status: {status} (attempt {attempt + 1})")

                if status in ['completed', 'done', 'ready']:
                    url = status_data.get('video_url') or status_data.get('url')
                    if url:
                        download_video(url, output_path)
                        return True
                elif status in ['failed', 'error']:
                    print(f"  Processing failed!")
                    return False

        print("  Timeout waiting for processing")
        return False

    print("  No video ID or URL in response")
    return False

def main():
    # Create output directory
    output_dir = Path(OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get available templates
    templates = list_caption_templates()
    template_id = None
    if templates and templates.get('templates'):
        # Use first template or a default
        template_id = templates['templates'][0].get('id')
        print(f"Using template: {template_id}\n")

    # Get videos
    videos = get_video_files()
    print(f"Found {len(videos)} videos to process\n")

    if not videos:
        print("No videos found!")
        return

    # Process each video
    success = 0
    failed = 0

    for i, video in enumerate(videos, 1):
        print(f"[{i}/{len(videos)}] Processing: {video.name}")
        size_mb = video.stat().st_size / (1024 * 1024)
        print(f"  Size: {size_mb:.1f} MB")

        if process_video(video, output_dir, template_id):
            success += 1
        else:
            failed += 1

        print()

    print(f"\nComplete! Success: {success}, Failed: {failed}")
    print(f"Captioned videos saved to: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
