#!/bin/bash
# ============================================================
#  FULL REDESIGN — ancestralhike.com post 1788
#  Run this from YOUR LOCAL TERMINAL
#  Usage:  bash redesign_1788.sh
# ============================================================
set -e

KEY="$HOME/.ssh/ancestralhike_id_ed25519"
HOST="ssh.ancestralhike.com"
PORT=18765
USER="u426-p9osfgnh24cv"
POST_ID=1788

# ── Save private key ────────────────────────────────────────
mkdir -p "$HOME/.ssh"
cat > "$KEY" << 'KEYEOF'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZWQyNTUx
OQAAACCnlarDUnKR+poUA4To+Qegt0+4cInq7QTAsv12DLjm1QAAAIin/Pdbp/z3WwAAAAtzc2gt
ZWQyNTUxOQAAACCnlarDUnKR+poUA4To+Qegt0+4cInq7QTAsv12DLjm1QAAAECXdHiVsr2pFQn9
0qQUqP+tExZypHTZgUZs/hR9ZKUGS6eVqsNScpH6mhQDhOj5B6C3T7hwiertBMCy/XYMuObVAAAA
AAECAwQF
-----END OPENSSH PRIVATE KEY-----
KEYEOF
chmod 600 "$KEY"

SSH="ssh -i $KEY -p $PORT -o StrictHostKeyChecking=no -o ConnectTimeout=15 $USER@$HOST"
SCP="scp -i $KEY -P $PORT -o StrictHostKeyChecking=no"

# ── Auto-detect WP root ──────────────────────────────────────
echo "→ Detecting WordPress root..."
WP_PATH=$($SSH "find /home/$USER/www -name 'wp-config.php' 2>/dev/null | head -1 | xargs dirname" 2>/dev/null || echo "")
if [ -z "$WP_PATH" ]; then
  WP_PATH="/home/$USER/www/ancestralhike.com/public_html"
  echo "  Could not auto-detect, using: $WP_PATH"
else
  echo "  Found: $WP_PATH"
fi
WP="wp --path=$WP_PATH"

# ── Test connection & WP-CLI ─────────────────────────────────
echo "→ Testing connection..."
$SSH "$WP --version" || { echo "ERROR: Cannot connect or WP-CLI not found"; exit 1; }

# ── Backup ───────────────────────────────────────────────────
echo "→ Backing up post $POST_ID..."
BACKUP="/tmp/backup_${POST_ID}_$(date +%Y%m%d_%H%M%S).json"
$SSH "$WP post meta get $POST_ID _elementor_data > $BACKUP && echo Backup saved: $BACKUP"

# ── Write PHP redesign script ────────────────────────────────
cat > /tmp/redesign_1788.php << 'PHPEOF'
<?php
/**
 * Full Elementor redesign for post 1788 — ancestralhike.com
 * Run via: wp eval-file /tmp/redesign_1788.php --path=WP_PATH
 */

function eid() {
    return substr(md5(uniqid(rand(), true)), 0, 8);
}

function mk_section(array $settings, array $cols): array {
    return [
        'id'       => eid(),
        'elType'   => 'section',
        'isInner'  => false,
        'settings' => $settings,
        'elements' => $cols,
    ];
}

function mk_col(int $size, array $widgets, array $extra = []): array {
    return [
        'id'       => eid(),
        'elType'   => 'column',
        'settings' => array_merge(['_column_size' => $size], $extra),
        'elements' => $widgets,
    ];
}

function mk_col_custom(int $inline_size, array $widgets, array $extra = []): array {
    return [
        'id'       => eid(),
        'elType'   => 'column',
        'settings' => array_merge(['_column_size' => $inline_size, '_inline_size' => $inline_size], $extra),
        'elements' => $widgets,
    ];
}

function mk_widget(string $type, array $settings): array {
    return [
        'id'         => eid(),
        'elType'     => 'widget',
        'widgetType' => $type,
        'settings'   => $settings,
        'elements'   => [],
    ];
}

// ── Media ────────────────────────────────────────────────────
$raw_imgs = get_posts([
    'post_type'      => 'attachment',
    'post_mime_type' => 'image',
    'posts_per_page' => -1,
    'post_status'    => 'inherit',
    'orderby'        => 'date',
    'order'          => 'ASC',
]);

$imgs = array_map(function($img) {
    return ['id' => $img->ID, 'url' => wp_get_attachment_url($img->ID)];
}, $raw_imgs);

$total_imgs = count($imgs);
echo "Found $total_imgs images in media library\n";

$hero_img   = $imgs[0]                      ?? ['id' => 0, 'url' => ''];
$break_img2 = $imgs[$total_imgs > 1 ? 1 : 0] ?? $hero_img;
$break_img3 = $imgs[$total_imgs > 2 ? 2 : 0] ?? $hero_img;
$intro_img  = $imgs[$total_imgs > 3 ? 3 : 0] ?? $hero_img;

$gallery = array_map(fn($i) => ['id' => (string)$i['id'], 'url' => $i['url']], $imgs);

// ── Available widgets ────────────────────────────────────────
$all_widgets   = array_keys(\Elementor\Plugin::$instance->widgets_manager->get_widget_types());
$has_gallery   = in_array('bdt-custom-gallery', $all_widgets);
$has_flip      = in_array('bdt-flip-box', $all_widgets);
$has_dual_btn  = in_array('bdt-dual-button', $all_widgets);
$has_bdt_acc   = in_array('bdt-accordion', $all_widgets);

$bdt_widgets = array_filter($all_widgets, fn($w) => strpos($w, 'bdt') !== false);
echo "Element Pack widgets available: " . count($bdt_widgets) . "\n";
echo "bdt-custom-gallery: " . ($has_gallery  ? 'YES' : 'NO') . "\n";
echo "bdt-flip-box: "       . ($has_flip     ? 'YES' : 'NO') . "\n";

// ── Common settings ──────────────────────────────────────────
$pad_desktop  = ['unit' => 'px', 'top' => '80', 'right' => '0', 'bottom' => '80', 'left' => '0', 'isLinked' => false];
$pad_parallax = ['unit' => 'px', 'top' => '80', 'right' => '30', 'bottom' => '80', 'left' => '30', 'isLinked' => false];
$boxed        = ['content_width' => 'boxed', 'boxed_width' => ['unit' => 'px', 'size' => 1200]];

function parallax_section(array $img, string $overlay, array $cols, array $extra_settings = []): array {
    global $pad_parallax;
    $settings = array_merge([
        'background_background'         => 'classic',
        'background_image'              => $img,
        'background_size'               => 'cover',
        'background_position'           => 'center center',
        'background_attachment'         => 'fixed',
        'background_overlay_background' => 'classic',
        'background_overlay_color'      => $overlay,
        'height'                        => 'min-height',
        'content_position'              => 'middle',
        'padding'                       => $pad_parallax,
    ], $extra_settings);
    return mk_section($settings, $cols);
}

// ════════════════════════════════════════════════════════════
// BUILD PAGE
// ════════════════════════════════════════════════════════════
$page = [];

// ── SECTION 1 — Hero ─────────────────────────────────────────
$page[] = parallax_section(
    $hero_img,
    'rgba(0,0,0,0.52)',
    [
        mk_col(100, [
            mk_widget('heading', [
                'title'                    => 'Bunkuany',
                'align'                    => 'center',
                'header_size'              => 'h1',
                'title_color'              => '#FFFFFF',
                'typography_typography'    => 'custom',
                'typography_font_size'     => ['unit' => 'px', 'size' => 72],
                'typography_font_weight'   => '700',
            ]),
            mk_widget('heading', [
                'title'                    => 'Trek Alternatif · 3 Jours · Sierra Nevada',
                'align'                    => 'center',
                'header_size'              => 'h3',
                'title_color'              => '#FFFFFF',
                'typography_typography'    => 'custom',
                'typography_font_size'     => ['unit' => 'px', 'size' => 22],
                'typography_letter_spacing'=> ['unit' => 'px', 'size' => 4],
            ]),
            mk_widget('divider', [
                'align'  => 'center',
                'color'  => '#2E7D32',
                'weight' => ['unit' => 'px', 'size' => 3],
                'width'  => ['unit' => '%', 'size' => 8],
                'gap'    => ['unit' => 'px', 'size' => 20],
            ]),
            mk_widget('text-editor', [
                'editor' => '<p style="text-align:center;color:#FFFFFF;font-size:18px;line-height:1.8;">Une aventure authentique guidée par des habitants de la Sierra Nevada de Santa Marta</p>',
            ]),
            mk_widget('button', [
                'text'              => 'Réserver Maintenant',
                'align'             => 'center',
                'size'              => 'lg',
                'border_radius'     => ['unit' => 'px', 'top' => 50, 'right' => 50, 'bottom' => 50, 'left' => 50, 'isLinked' => true],
                'background_color'  => '#2E7D32',
                'button_text_color' => '#FFFFFF',
            ]),
        ], ['content_position' => 'middle']),
    ],
    ['min_height' => ['unit' => 'vh', 'size' => 100]]
);

// ── SECTION 2 — Stats Bar ────────────────────────────────────
$stats = [
    ['icon' => 'fas fa-hiking',  'value' => '3 Jours',  'label' => 'Durée du Trek'],
    ['icon' => 'fas fa-users',   'value' => '12 max',   'label' => 'Taille du Groupe'],
    ['icon' => 'fas fa-star',    'value' => '4.9/5',    'label' => 'Note Voyageurs'],
    ['icon' => 'fas fa-leaf',    'value' => '100%',     'label' => 'Guides Locaux'],
];
$stat_cols = array_map(fn($s) => mk_col(25, [
    mk_widget('icon-box', [
        'title_text'        => $s['value'],
        'description_text'  => $s['label'],
        'selected_icon'     => ['value' => $s['icon'], 'library' => 'fa-solid'],
        'title_color'       => '#FFFFFF',
        'description_color' => '#FFFFFF',
        'icon_color'        => '#FFFFFF',
        'align'             => 'center',
        'title_typography_typography'       => 'custom',
        'title_typography_font_size'        => ['unit' => 'px', 'size' => 28],
        'title_typography_font_weight'      => '700',
        'description_typography_typography' => 'custom',
        'description_typography_font_size'  => ['unit' => 'px', 'size' => 14],
    ]),
]), $stats);

$page[] = mk_section([
    'background_background' => 'classic',
    'background_color'      => '#1B5E20',
    'padding'               => ['unit' => 'px', 'top' => '40', 'right' => '0', 'bottom' => '40', 'left' => '0', 'isLinked' => false],
], $stat_cols);

// ── SECTION 3 — Introduction ─────────────────────────────────
$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#FFFFFF',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col_custom(60, [
        mk_widget('heading', [
            'title'                  => 'Qui sommes-nous ?',
            'header_size'            => 'h2',
            'title_color'            => '#2E7D32',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 32],
        ]),
        mk_widget('text-editor', [
            'editor' => '<p style="color:#1a1a1a;font-size:16px;line-height:1.9;">Ancestral Hike est un collectif de guides locaux nés dans la Sierra Nevada de Santa Marta. Nous ne sommes pas une agence de voyage classique — nous sommes des habitants qui vous ouvrent les portes de notre territoire, de notre culture et de nos traditions ancestrales Tayrona.</p>',
        ]),
    ]),
    mk_col_custom(40, [
        mk_widget('image', [
            'image'                 => $intro_img,
            'image_size'            => 'large',
            'align'                 => 'center',
            'border_radius'         => ['unit' => 'px', 'top' => 12, 'right' => 12, 'bottom' => 12, 'left' => 12, 'isLinked' => true],
            'box_shadow_box_shadow_type' => 'yes',
            'box_shadow_box_shadow' => ['horizontal' => 0, 'vertical' => 8, 'blur' => 25, 'spread' => 0, 'color' => 'rgba(0,0,0,0.15)'],
        ]),
    ]),
]);

// ── SECTION 4 — Parallax Break ───────────────────────────────
$page[] = parallax_section(
    $break_img2,
    'rgba(0,0,0,0.6)',
    [
        mk_col(100, [
            mk_widget('heading', [
                'title'                  => '« Suivez les pas de vos ancêtres »',
                'align'                  => 'center',
                'header_size'            => 'h2',
                'title_color'            => '#FFFFFF',
                'typography_typography'  => 'custom',
                'typography_font_size'   => ['unit' => 'px', 'size' => 42],
                'typography_font_style'  => 'italic',
            ]),
            mk_widget('heading', [
                'title'                  => 'Un chemin oublié, une civilisation vivante',
                'align'                  => 'center',
                'header_size'            => 'h4',
                'title_color'            => '#FFFFFF',
                'typography_typography'  => 'custom',
                'typography_font_size'   => ['unit' => 'px', 'size' => 20],
            ]),
        ], ['content_position' => 'middle']),
    ],
    ['min_height' => ['unit' => 'px', 'size' => 500]]
);

// ── SECTION 5 — Itinerary ────────────────────────────────────
$accordion_tabs = [
    [
        'tab_title'   => 'JOUR 1 — Immersion dans la Jungle',
        'tab_content' => '<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Prise en charge à Santa Marta à 8h45. Route vers Calabazo, porte d\'entrée de la Sierra Nevada. Début du trek à travers la forêt tropicale humide, traversée de rivières, observation de la faune. Arrivée au premier campement en fin d\'après-midi. Dîner traditionnel autour du feu.</p>',
    ],
    [
        'tab_title'   => 'JOUR 2 — Les Ruines de Bunkuany',
        'tab_content' => '<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Montée progressive vers le site archéologique de Bunkuany (altitude 900m). Découverte des terrasses et structures en pierre des anciens Tayrona, guidée par un membre de la communauté Kogui. Baignade en cascade. Nuit en hamac ou tente sous les étoiles.</p>',
    ],
    [
        'tab_title'   => 'JOUR 3 — Rencontre Culturelle &amp; Retour',
        'tab_content' => '<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Descente matinale par un sentier différent. Visite d\'un village indigène Kogui, échange culturel et artisanat local. Retour à Santa Marta en début d\'après-midi.</p>',
    ],
];

$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#F7F9F4',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col(100, [
        mk_widget('heading', [
            'title'                  => 'Le Programme Jour par Jour',
            'align'                  => 'center',
            'header_size'            => 'h2',
            'title_color'            => '#2E7D32',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 32],
        ]),
        mk_widget('accordion', [
            'tabs'                           => $accordion_tabs,
            'title_color'                    => '#2E7D32',
            'border_color'                   => '#2E7D32',
            'active_color'                   => '#2E7D32',
            'tab_active_color'               => '#2E7D32',
            'title_typography_typography'    => 'custom',
            'title_typography_font_size'     => ['unit' => 'px', 'size' => 17],
            'title_typography_font_weight'   => '600',
        ]),
    ]),
]);

// ── SECTION 6 — Included / Not included ─────────────────────
$included = [
    'Transport aller-retour depuis Santa Marta',
    'Guide local bilingue (FR/ES/EN)',
    '2 nuits en campement',
    'Tous les repas (petit-déj, déjeuner, dîner)',
    'Équipement de camping',
    'Droits d\'entrée au territoire',
    'Assurance activité',
];
$excluded = [
    'Vols internationaux',
    'Assurance voyage annulation',
    'Dépenses personnelles',
    'Pourboires (optionnels)',
    'Équipement de randonnée personnel',
];
$mk_list = fn(array $items, string $icon, string $color) =>
    array_map(fn($t) => [
        'text'          => $t,
        'selected_icon' => ['value' => $icon, 'library' => 'fa-solid'],
    ], $items);

$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#FFFFFF',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col(100, [
        mk_widget('heading', [
            'title'                  => 'Ce qui est Inclus',
            'align'                  => 'center',
            'header_size'            => 'h2',
            'title_color'            => '#2E7D32',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 32],
        ]),
    ]),
    mk_col(50, [
        mk_widget('heading', ['title' => '✅ Inclus', 'header_size' => 'h3', 'title_color' => '#2E7D32']),
        mk_widget('icon-list', [
            'icon_list'  => $mk_list($included, 'fas fa-check-circle', '#2E7D32'),
            'icon_color' => '#2E7D32',
            'text_color' => '#1a1a1a',
            'space_between' => ['unit' => 'px', 'size' => 12],
        ]),
    ]),
    mk_col(50, [
        mk_widget('heading', ['title' => '❌ Non Inclus', 'header_size' => 'h3', 'title_color' => '#c62828']),
        mk_widget('icon-list', [
            'icon_list'  => $mk_list($excluded, 'fas fa-times-circle', '#c62828'),
            'icon_color' => '#c62828',
            'text_color' => '#1a1a1a',
            'space_between' => ['unit' => 'px', 'size' => 12],
        ]),
    ]),
]);

// ── SECTION 7 — Parallax Break 3 ────────────────────────────
$page[] = parallax_section(
    $break_img3,
    'rgba(20,60,20,0.65)',
    [
        mk_col(100, [
            mk_widget('heading', [
                'title'                  => 'La Sierra Nevada en Images',
                'align'                  => 'center',
                'header_size'            => 'h2',
                'title_color'            => '#FFFFFF',
                'typography_typography'  => 'custom',
                'typography_font_size'   => ['unit' => 'px', 'size' => 42],
            ]),
            mk_widget('text-editor', [
                'editor' => '<p style="text-align:center;color:#FFFFFF;font-size:16px;line-height:1.8;">Découvrez la beauté brute de l\'une des régions les plus biodiverses au monde</p>',
            ]),
        ], ['content_position' => 'middle']),
    ],
    ['min_height' => ['unit' => 'px', 'size' => 450]]
);

// ── SECTION 8 — Gallery ──────────────────────────────────────
if ($has_gallery) {
    $gallery_widget = mk_widget('bdt-custom-gallery', [
        'gallery'         => $gallery,
        'layout'          => 'masonry',
        'column'          => '3',
        'column_tablet'   => '2',
        'column_mobile'   => '1',
        'item_gap'        => ['unit' => 'px', 'size' => 12],
        'show_lightbox'   => 'yes',
        'lightbox'        => 'yes',
        'overlay_hover_animation' => 'zoom-in',
        'image_height'    => ['unit' => 'px', 'size' => 280],
    ]);
} else {
    $gallery_widget = mk_widget('gallery', [
        'wp_gallery'     => $gallery,
        'gallery_layout' => 'justified',
        'gallery_columns' => '3',
        'gallery_link'   => 'file',
        'open_lightbox'  => 'yes',
        'gap'            => ['unit' => 'px', 'size' => 12],
    ]);
}

$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#FFFFFF',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col(100, [$gallery_widget]),
]);

// ── SECTION 9 — Why Choose ───────────────────────────────────
$boxes = [
    ['front' => '🌿 Guides Autochtones',   'back' => 'Nos guides sont nés ici. Ils connaissent chaque sentier, chaque plante, chaque histoire.'],
    ['front' => '🤝 Impact Communautaire', 'back' => 'Votre aventure finance directement les familles locales et la préservation culturelle.'],
    ['front' => '⭐ Expérience Unique',     'back' => 'Aucune agence ne vous offrira cet accès. Nous vivons ici. Vous serez nos invités.'],
];

if ($has_flip) {
    $box_widgets = array_map(fn($b) => mk_widget('bdt-flip-box', [
        'front_title_text'        => $b['front'],
        'back_description_text'   => $b['back'],
        'front_title_color'       => '#1a1a1a',
        'back_description_color'  => '#FFFFFF',
        'front_background_color'  => '#FFFFFF',
        'back_background_color'   => '#2E7D32',
        'border_radius'           => ['unit' => 'px', 'top' => 8, 'right' => 8, 'bottom' => 8, 'left' => 8, 'isLinked' => true],
    ]), $boxes);
} else {
    $box_widgets = array_map(fn($b) => mk_widget('icon-box', [
        'title_text'       => $b['front'],
        'description_text' => $b['back'],
        'title_color'      => '#2E7D32',
        'description_color'=> '#1a1a1a',
        'align'            => 'center',
        '_css_classes'     => 'why-box',
    ]), $boxes);
}

$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#F7F9F4',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col(100, [
        mk_widget('heading', [
            'title'                  => 'Pourquoi Choisir Ancestral Hike ?',
            'align'                  => 'center',
            'header_size'            => 'h2',
            'title_color'            => '#2E7D32',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 32],
        ]),
    ]),
    mk_col(33, [$box_widgets[0]]),
    mk_col(33, [$box_widgets[1]]),
    mk_col(34, [$box_widgets[2]]),
]);

// ── SECTION 10 — Testimonials ────────────────────────────────
$testi_html = '
<div style="display:flex;gap:24px;flex-wrap:wrap;justify-content:center;">
    <div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
        <p style="color:#F9A825;font-size:18px;margin:0 0 12px;">⭐⭐⭐⭐⭐</p>
        <p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Une expérience qui change la vie. Nos guides connaissaient chaque plante, chaque histoire. Je recommande à 100%.&rdquo;</p>
        <p style="color:#2E7D32;font-weight:600;margin-top:16px;">— Marie L., France</p>
    </div>
    <div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
        <p style="color:#F9A825;font-size:18px;margin:0 0 12px;">⭐⭐⭐⭐⭐</p>
        <p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Complètement différent des tours classiques. On se sent vraiment accueillis par la communauté locale.&rdquo;</p>
        <p style="color:#2E7D32;font-weight:600;margin-top:16px;">— Thomas B., Belgique</p>
    </div>
    <div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
        <p style="color:#F9A825;font-size:18px;margin:0 0 12px;">⭐⭐⭐⭐⭐</p>
        <p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Les ruines de Bunkuany m&rsquo;ont coupé le souffle. Le guide Kogui était incroyable.&rdquo;</p>
        <p style="color:#2E7D32;font-weight:600;margin-top:16px;">— Sophie M., Suisse</p>
    </div>
</div>';

$page[] = mk_section(array_merge([
    'background_background' => 'classic',
    'background_color'      => '#FFFFFF',
    'padding'               => $pad_desktop,
], $boxed), [
    mk_col(100, [
        mk_widget('heading', [
            'title'                  => 'Ce que disent nos Voyageurs',
            'align'                  => 'center',
            'header_size'            => 'h2',
            'title_color'            => '#2E7D32',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 32],
        ]),
        mk_widget('text-editor', ['editor' => $testi_html]),
    ]),
]);

// ── SECTION 11 — Final CTA ───────────────────────────────────
$page[] = mk_section([
    'background_background' => 'classic',
    'background_color'      => '#1B5E20',
    'padding'               => ['unit' => 'px', 'top' => '100', 'right' => '30', 'bottom' => '100', 'left' => '30', 'isLinked' => false],
    'content_position'      => 'middle',
], [
    mk_col(100, [
        mk_widget('heading', [
            'title'                  => 'Prêt pour l\'Aventure ?',
            'align'                  => 'center',
            'header_size'            => 'h2',
            'title_color'            => '#FFFFFF',
            'typography_typography'  => 'custom',
            'typography_font_size'   => ['unit' => 'px', 'size' => 42],
        ]),
        mk_widget('text-editor', [
            'editor' => '<p style="text-align:center;color:#FFFFFF;font-size:18px;line-height:1.8;">Rejoignez le prochain groupe. Places limitées à 12 personnes.</p>',
        ]),
        mk_widget('button', [
            'text'              => 'Réserver Maintenant',
            'align'             => 'center',
            'size'              => 'lg',
            'border_radius'     => ['unit' => 'px', 'top' => 50, 'right' => 50, 'bottom' => 50, 'left' => 50, 'isLinked' => true],
            'background_color'  => '#FFFFFF',
            'button_text_color' => '#2E7D32',
            'typography_typography' => 'custom',
            'typography_font_weight' => '700',
        ]),
        mk_widget('button', [
            'text'              => '💬 WhatsApp',
            'link'              => ['url' => 'https://api.whatsapp.com/send?phone=573042233019', 'is_external' => 'on'],
            'align'             => 'center',
            'size'              => 'lg',
            'border_radius'     => ['unit' => 'px', 'top' => 50, 'right' => 50, 'bottom' => 50, 'left' => 50, 'isLinked' => true],
            'border_width'      => ['unit' => 'px', 'top' => 2, 'right' => 2, 'bottom' => 2, 'left' => 2, 'isLinked' => true],
            'border_color'      => '#FFFFFF',
            'background_color'  => 'rgba(0,0,0,0)',
            'button_text_color' => '#FFFFFF',
        ]),
    ], ['content_position' => 'middle']),
]);

// ════════════════════════════════════════════════════════════
// APPLY TO POST
// ════════════════════════════════════════════════════════════
$post_id = 1788;
$json    = json_encode($page, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

// wp_slash is required before update_post_meta for Elementor data
update_post_meta($post_id, '_elementor_data',      wp_slash($json));
update_post_meta($post_id, '_elementor_edit_mode', 'builder');
update_post_meta($post_id, '_elementor_template_type', 'wp-page');

// Clear Elementor CSS cache
\Elementor\Plugin::$instance->files_manager->clear_cache();

echo "\n===========================================\n";
echo "SUCCESS: Post $post_id redesigned\n";
echo "Sections built: " . count($page) . "\n";
echo "Images in gallery: $total_imgs\n";
echo "Gallery widget: "  . ($has_gallery ? 'bdt-custom-gallery' : 'elementor native gallery') . "\n";
echo "Flip boxes: "      . ($has_flip    ? 'bdt-flip-box'       : 'elementor icon-box')       . "\n";
echo "===========================================\n";
echo "Visit: https://ancestralhike.com/?p=1788&elementor-preview=$post_id\n";
PHPEOF

# ── Upload & execute ─────────────────────────────────────────
echo "→ Uploading PHP script..."
$SCP /tmp/redesign_1788.php $USER@$HOST:/tmp/redesign_1788.php

echo "→ Running redesign..."
$SSH "wp eval-file /tmp/redesign_1788.php --path=$WP_PATH"

echo "→ Flushing rewrite rules & object cache..."
$SSH "$WP rewrite flush && ($WP cache flush 2>/dev/null || true)"

echo "→ Cleaning up..."
$SSH "rm -f /tmp/redesign_1788.php"
rm -f /tmp/redesign_1788.php

echo ""
echo "✓ Done. Preview: https://ancestralhike.com/?p=1788"
echo "✓ Backup saved on server at: $BACKUP"
