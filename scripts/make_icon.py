#!/usr/bin/env python3
"""Генерация иконки Tennis Score: градиент Уимблдона + теннисный мяч.

Рисуем в 4x и уменьшаем с антиалиасингом. Результат кладём в
App/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png (единственный
размер 1024 — современный single-size формат каталога иконок).
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 4  # суперсэмплинг
S = SIZE * SS

# Палитра Уимблдона
GRASS_TOP = (27, 94, 51)
GRASS_BOTTOM = (10, 48, 24)
PURPLE = (94, 53, 134)
BALL_LIGHT = (237, 250, 120)
BALL_MID = (216, 235, 70)
BALL_DARK = (160, 190, 30)
SEAM = (250, 252, 240)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    img = Image.new("RGB", (S, S), GRASS_TOP)
    draw = ImageDraw.Draw(img)

    # Вертикальный градиент травы
    for y in range(S):
        t = y / S
        draw.line([(0, y), (S, y)], fill=lerp(GRASS_TOP, GRASS_BOTTOM, t))

    # Едва заметные «полосы газона»
    stripe = Image.new("L", (S, S), 0)
    stripe_draw = ImageDraw.Draw(stripe)
    stripe_count = 7
    for i in range(stripe_count):
        if i % 2 == 0:
            x0 = S * i / stripe_count
            x1 = S * (i + 1) / stripe_count
            stripe_draw.rectangle([x0, 0, x1, S], fill=18)
    img = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), img, stripe.point(lambda v: v // 3))

    draw = ImageDraw.Draw(img)

    # Фиолетовая дуга Уимблдона внизу
    arc_h = S * 0.62
    draw.ellipse(
        [-S * 0.35, S - arc_h * 0.55, S * 1.35, S + arc_h],
        fill=PURPLE,
    )
    # Тонкая светлая линия над дугой — как разметка корта
    draw.ellipse(
        [-S * 0.35 - 8, S - arc_h * 0.55 - S * 0.012, S * 1.35 + 8, S + arc_h],
        outline=(255, 255, 255, 90),
        width=int(S * 0.008),
    )
    draw.ellipse(
        [-S * 0.35, S - arc_h * 0.55, S * 1.35, S + arc_h],
        fill=PURPLE,
    )

    # Мягкая тень под мячом (плоский эллипс на «корте»)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    cx, cy = S * 0.5, S * 0.46
    r = S * 0.27
    shadow_draw.ellipse(
        [cx - r * 0.95, cy + r * 0.92, cx + r * 0.95, cy + r * 1.38],
        fill=(0, 0, 0, 80),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.03))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")

    # Мяч: радиальный градиент
    ball = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ball_draw = ImageDraw.Draw(ball)
    # База: весь круг тёмным тоном, чтобы не осталось непрокрашенных зон
    ball_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=BALL_DARK)
    steps = 220
    light_center = (cx - r * 0.35, cy - r * 0.4)
    for i in range(steps, 0, -1):
        t = i / steps
        rr = r * t
        # Чем дальше от блика, тем темнее
        color = lerp(BALL_LIGHT, BALL_DARK, t * t)
        ball_draw.ellipse(
            [
                light_center[0] - rr - (cx - light_center[0]) * t,
                light_center[1] - rr - (cy - light_center[1]) * t,
                light_center[0] + rr + (cx - light_center[0]) * t,
                light_center[1] + rr + (cy - light_center[1]) * t,
            ],
            fill=color,
        )

    # Маска круга мяча
    mask = Image.new("L", (S, S), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    ball.putalpha(mask)

    # Швы мяча: две дуги
    seam_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    seam_draw = ImageDraw.Draw(seam_layer)
    seam_w = int(S * 0.018)

    # Левая дуга — окружность, центр которой смещён влево от мяча
    seam_r = r * 1.55
    lx = cx - r * 1.78
    seam_draw.arc(
        [lx - seam_r, cy - seam_r, lx + seam_r, cy + seam_r],
        start=-44,
        end=44,
        fill=SEAM,
        width=seam_w,
    )
    rx = cx + r * 1.78
    seam_draw.arc(
        [rx - seam_r, cy - seam_r, rx + seam_r, cy + seam_r],
        start=136,
        end=224,
        fill=SEAM,
        width=seam_w,
    )
    seam_layer.putalpha(
        Image.composite(seam_layer.split()[3], Image.new("L", (S, S), 0), mask)
    )

    img = Image.alpha_composite(img.convert("RGBA"), ball)
    img = Image.alpha_composite(img, seam_layer)

    # Лёгкий глянец сверху мяча
    gloss = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gloss_draw = ImageDraw.Draw(gloss)
    gloss_draw.ellipse(
        [cx - r * 0.62, cy - r * 0.92, cx + r * 0.25, cy - r * 0.38],
        fill=(255, 255, 255, 38),
    )
    gloss = gloss.filter(ImageFilter.GaussianBlur(S * 0.03))
    gloss.putalpha(Image.composite(gloss.split()[3], Image.new("L", (S, S), 0), mask))
    img = Image.alpha_composite(img, gloss)

    final = img.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)

    out_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "App", "Assets.xcassets", "AppIcon.appiconset",
    )
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "AppIcon1024.png")
    final.save(out_path, "PNG")
    print(f"OK: {out_path}")


if __name__ == "__main__":
    main()
