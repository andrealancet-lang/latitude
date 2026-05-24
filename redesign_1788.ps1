# ============================================================
#  FULL REDESIGN — ancestralhike.com post 1788
#  Run this in PowerShell on Windows 10/11
#  Open PowerShell and paste:
#    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#    .\redesign_1788.ps1
# ============================================================

$KEY  = "$env:USERPROFILE\.ssh\ancestralhike_id_ed25519"
$HOST = "ssh.ancestralhike.com"
$PORT = 18765
$USER = "u426-p9osfgnh24cv"
$POST = 1788

# ── Save private key ─────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh" | Out-Null

@"
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZWQyNTUx
OQAAACCnlarDUnKR+poUA4To+Qegt0+4cInq7QTAsv12DLjm1QAAAIin/Pdbp/z3WwAAAAtzc2gt
ZWQyNTUxOQAAACCnlarDUnKR+poUA4To+Qegt0+4cInq7QTAsv12DLjm1QAAAECXdHiVsr2pFQn9
0qQUqP+tExZypHTZgUZs/hR9ZKUGS6eVqsNScpH6mhQDhOj5B6C3T7hwiertBMCy/XYMuObVAAAA
AAECAwQF
-----END OPENSSH PRIVATE KEY-----
"@ | Set-Content -Path $KEY -Encoding ascii -NoNewline

# Fix key permissions (Windows requires this for SSH)
icacls $KEY /inheritance:r /grant:r "${env:USERNAME}:(R)" | Out-Null

# ── SSH helper ───────────────────────────────────────────────
function SSH-Run($cmd) {
    ssh -i $KEY -p $PORT -o StrictHostKeyChecking=no -o ConnectTimeout=15 "${USER}@${HOST}" $cmd
}

# ── Test connection ───────────────────────────────────────────
Write-Host "-> Testing connection..." -ForegroundColor Cyan
SSH-Run "echo CONNECTED"
if ($LASTEXITCODE -ne 0) { Write-Error "Cannot connect. Check your network."; exit 1 }

# ── Auto-detect WP root ──────────────────────────────────────
Write-Host "-> Detecting WordPress root..." -ForegroundColor Cyan
$WP_PATH = SSH-Run "find /home/$USER/www -name 'wp-config.php' 2>/dev/null | head -1 | xargs dirname"
if (-not $WP_PATH) { $WP_PATH = "/home/$USER/www/ancestralhike.com/public_html" }
Write-Host "   WP root: $WP_PATH" -ForegroundColor Green

# ── Backup ───────────────────────────────────────────────────
Write-Host "-> Backing up post $POST..." -ForegroundColor Cyan
$DATE = Get-Date -Format "yyyyMMdd_HHmmss"
SSH-Run "wp --path=$WP_PATH post meta get $POST _elementor_data > /tmp/backup_${POST}_${DATE}.json && echo Backup OK"

# ── Write PHP redesign script locally, then upload ───────────
Write-Host "-> Building redesign script..." -ForegroundColor Cyan

$PHP = @'
<?php
function eid(){return substr(md5(uniqid(rand(),true)),0,8);}
function mk_section($s,$cols){return['id'=>eid(),'elType'=>'section','isInner'=>false,'settings'=>$s,'elements'=>$cols];}
function mk_col($sz,$w,$ex=[]){return['id'=>eid(),'elType'=>'column','settings'=>array_merge(['_column_size'=>$sz],$ex),'elements'=>$w];}
function mk_colc($sz,$w,$ex=[]){return['id'=>eid(),'elType'=>'column','settings'=>array_merge(['_column_size'=>$sz,'_inline_size'=>$sz],$ex),'elements'=>$w];}
function mk_widget($t,$s){return['id'=>eid(),'elType'=>'widget','widgetType'=>$t,'settings'=>$s,'elements'=>[]];}

$imgs=get_posts(['post_type'=>'attachment','post_mime_type'=>'image','posts_per_page'=>-1,'post_status'=>'inherit','orderby'=>'date','order'=>'ASC']);
$imgs=array_map(fn($i)=>['id'=>$i->ID,'url'=>wp_get_attachment_url($i->ID)],$imgs);
$n=count($imgs);echo "Images found: $n\n";
$h=$imgs[0]??['id'=>0,'url'=>''];
$b2=$imgs[$n>1?1:0]??$h;
$b3=$imgs[$n>2?2:0]??$h;
$bi=$imgs[$n>3?3:0]??$h;
$gal=array_map(fn($i)=>['id'=>(string)$i['id'],'url'=>$i['url']],$imgs);

$aw=array_keys(\Elementor\Plugin::$instance->widgets_manager->get_widget_types());
$hg=in_array('bdt-custom-gallery',$aw);
$hf=in_array('bdt-flip-box',$aw);
echo "bdt-custom-gallery:".($hg?'YES':'NO')."\nbdt-flip-box:".($hf?'YES':'NO')."\n";

$pp=['unit'=>'px','top'=>'80','right'=>'0','bottom'=>'80','left'=>'0','isLinked'=>false];
$bx=['content_width'=>'boxed','boxed_width'=>['unit'=>'px','size'=>1200]];
function pxsec($img,$ov,$cols,$ex=[]){global $pp;
  $s=array_merge(['background_background'=>'classic','background_image'=>$img,'background_size'=>'cover','background_position'=>'center center','background_attachment'=>'fixed','background_overlay_background'=>'classic','background_overlay_color'=>$ov,'height'=>'min-height','content_position'=>'middle','padding'=>['unit'=>'px','top'=>'80','right'=>'30','bottom'=>'80','left'=>'30','isLinked'=>false]],$ex);
  return mk_section($s,$cols);}

$page=[];

// S1 HERO
$page[]=pxsec($h,'rgba(0,0,0,0.52)',[mk_col(100,[
  mk_widget('heading',['title'=>'Bunkuany','align'=>'center','header_size'=>'h1','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>72],'typography_font_weight'=>'700']),
  mk_widget('heading',['title'=>'Trek Alternatif · 3 Jours · Sierra Nevada','align'=>'center','header_size'=>'h3','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>22],'typography_letter_spacing'=>['unit'=>'px','size'=>4]]),
  mk_widget('divider',['align'=>'center','color'=>'#2E7D32','weight'=>['unit'=>'px','size'=>3],'width'=>['unit'=>'%','size'=>8],'gap'=>['unit'=>'px','size'=>20]]),
  mk_widget('text-editor',['editor'=>'<p style="text-align:center;color:#FFFFFF;font-size:18px;line-height:1.8;">Une aventure authentique guid&eacute;e par des habitants de la Sierra Nevada de Santa Marta</p>']),
  mk_widget('button',['text'=>'R&eacute;server Maintenant','align'=>'center','size'=>'lg','border_radius'=>['unit'=>'px','top'=>50,'right'=>50,'bottom'=>50,'left'=>50,'isLinked'=>true],'background_color'=>'#2E7D32','button_text_color'=>'#FFFFFF']),
],['content_position'=>'middle'])],['min_height'=>['unit'=>'vh','size'=>100]]);

// S2 STATS
$stats=[['fas fa-hiking','3 Jours','Dur&eacute;e du Trek'],['fas fa-users','12 max','Taille du Groupe'],['fas fa-star','4.9/5','Note Voyageurs'],['fas fa-leaf','100%','Guides Locaux']];
$sc=array_map(fn($s)=>mk_col(25,[mk_widget('icon-box',['title_text'=>$s[1],'description_text'=>$s[2],'selected_icon'=>['value'=>$s[0],'library'=>'fa-solid'],'title_color'=>'#FFFFFF','description_color'=>'#FFFFFF','icon_color'=>'#FFFFFF','align'=>'center','title_typography_typography'=>'custom','title_typography_font_size'=>['unit'=>'px','size'=>28],'title_typography_font_weight'=>'700'])]),$stats);
$page[]=mk_section(['background_background'=>'classic','background_color'=>'#1B5E20','padding'=>['unit'=>'px','top'=>'40','right'=>'0','bottom'=>'40','left'=>'0','isLinked'=>false]],$sc);

// S3 INTRO
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#FFFFFF','padding'=>$pp],$bx),[
  mk_colc(60,[mk_widget('heading',['title'=>'Qui sommes-nous ?','header_size'=>'h2','title_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>32]]),mk_widget('text-editor',['editor'=>'<p style="color:#1a1a1a;font-size:16px;line-height:1.9;">Ancestral Hike est un collectif de guides locaux n&eacute;s dans la Sierra Nevada de Santa Marta. Nous ne sommes pas une agence de voyage classique &mdash; nous sommes des habitants qui vous ouvrent les portes de notre territoire, de notre culture et de nos traditions ancestrales Tayrona.</p>'])]),
  mk_colc(40,[mk_widget('image',['image'=>$bi,'image_size'=>'large','align'=>'center','border_radius'=>['unit'=>'px','top'=>12,'right'=>12,'bottom'=>12,'left'=>12,'isLinked'=>true]])]),
]);

// S4 PARALLAX BREAK
$page[]=pxsec($b2,'rgba(0,0,0,0.6)',[mk_col(100,[
  mk_widget('heading',['title'=>'&laquo;&nbsp;Suivez les pas de vos anc&ecirc;tres&nbsp;&raquo;','align'=>'center','header_size'=>'h2','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>42],'typography_font_style'=>'italic']),
  mk_widget('heading',['title'=>'Un chemin oubli&eacute;, une civilisation vivante','align'=>'center','header_size'=>'h4','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>20]]),
],['content_position'=>'middle'])],['min_height'=>['unit'=>'px','size'=>500]]);

// S5 ITINERARY
$tabs=[['tab_title'=>'JOUR 1 &mdash; Immersion dans la Jungle','tab_content'=>'<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Prise en charge &agrave; Santa Marta &agrave; 8h45. Route vers Calabazo, porte d\'entr&eacute;e de la Sierra Nevada. D&eacute;but du trek &agrave; travers la for&ecirc;t tropicale humide, travers&eacute;e de rivi&egrave;res, observation de la faune. Arriv&eacute;e au premier campement en fin d\'apr&egrave;s-midi. D&icirc;ner traditionnel autour du feu.</p>'],['tab_title'=>'JOUR 2 &mdash; Les Ruines de Bunkuany','tab_content'=>'<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Mont&eacute;e progressive vers le site arch&eacute;ologique de Bunkuany (altitude 900m). D&eacute;couverte des terrasses et structures en pierre des anciens Tayrona, guid&eacute;e par un membre de la communaut&eacute; Kogui. Baignade en cascade. Nuit en hamac ou tente sous les &eacute;toiles.</p>'],['tab_title'=>'JOUR 3 &mdash; Rencontre Culturelle &amp; Retour','tab_content'=>'<p style="color:#1a1a1a;font-size:15px;line-height:1.8;">Descente matinale par un sentier diff&eacute;rent. Visite d\'un village indig&egrave;ne Kogui, &eacute;change culturel et artisanat local. Retour &agrave; Santa Marta en d&eacute;but d\'apr&egrave;s-midi.</p>']];
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#F7F9F4','padding'=>$pp],$bx),[mk_col(100,[
  mk_widget('heading',['title'=>'Le Programme Jour par Jour','align'=>'center','header_size'=>'h2','title_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>32]]),
  mk_widget('accordion',['tabs'=>$tabs,'title_color'=>'#2E7D32','border_color'=>'#2E7D32','active_color'=>'#2E7D32','title_typography_typography'=>'custom','title_typography_font_size'=>['unit'=>'px','size'=>17],'title_typography_font_weight'=>'600']),
])]);

// S6 INCLUDED
$inc=[['text'=>'Transport aller-retour depuis Santa Marta','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'Guide local bilingue (FR/ES/EN)','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'2 nuits en campement','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'Tous les repas (petit-d&eacute;j, d&eacute;jeuner, d&icirc;ner)','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'&Eacute;quipement de camping','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'Droits d\'entr&eacute;e au territoire','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']],['text'=>'Assurance activit&eacute;','selected_icon'=>['value'=>'fas fa-check-circle','library'=>'fa-solid']]];
$exc=[['text'=>'Vols internationaux','selected_icon'=>['value'=>'fas fa-times-circle','library'=>'fa-solid']],['text'=>'Assurance voyage annulation','selected_icon'=>['value'=>'fas fa-times-circle','library'=>'fa-solid']],['text'=>'D&eacute;penses personnelles','selected_icon'=>['value'=>'fas fa-times-circle','library'=>'fa-solid']],['text'=>'Pourboires (optionnels)','selected_icon'=>['value'=>'fas fa-times-circle','library'=>'fa-solid']],['text'=>'&Eacute;quipement de randonn&eacute;e personnel','selected_icon'=>['value'=>'fas fa-times-circle','library'=>'fa-solid']]];
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#FFFFFF','padding'=>$pp],$bx),[
  mk_col(100,[mk_widget('heading',['title'=>'Ce qui est Inclus','align'=>'center','header_size'=>'h2','title_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>32]])]),
  mk_col(50,[mk_widget('heading',['title'=>'&#x2705; Inclus','header_size'=>'h3','title_color'=>'#2E7D32']),mk_widget('icon-list',['icon_list'=>$inc,'icon_color'=>'#2E7D32','text_color'=>'#1a1a1a','space_between'=>['unit'=>'px','size'=>12]])]),
  mk_col(50,[mk_widget('heading',['title'=>'&#x274C; Non Inclus','header_size'=>'h3','title_color'=>'#c62828']),mk_widget('icon-list',['icon_list'=>$exc,'icon_color'=>'#c62828','text_color'=>'#1a1a1a','space_between'=>['unit'=>'px','size'=>12]])]),
]);

// S7 PARALLAX BREAK 3
$page[]=pxsec($b3,'rgba(20,60,20,0.65)',[mk_col(100,[
  mk_widget('heading',['title'=>'La Sierra Nevada en Images','align'=>'center','header_size'=>'h2','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>42]]),
  mk_widget('text-editor',['editor'=>'<p style="text-align:center;color:#FFFFFF;font-size:16px;line-height:1.8;">D&eacute;couvrez la beaut&eacute; brute de l\'une des r&eacute;gions les plus biodiverses au monde</p>']),
],['content_position'=>'middle'])],['min_height'=>['unit'=>'px','size'=>450]]);

// S8 GALLERY
if($hg){$gw=mk_widget('bdt-custom-gallery',['gallery'=>$gal,'layout'=>'masonry','column'=>'3','column_tablet'=>'2','column_mobile'=>'1','item_gap'=>['unit'=>'px','size'=>12],'show_lightbox'=>'yes','lightbox'=>'yes','overlay_hover_animation'=>'zoom-in','image_height'=>['unit'=>'px','size'=>280]]);}
else{$gw=mk_widget('gallery',['wp_gallery'=>$gal,'gallery_layout'=>'justified','gallery_columns'=>'3','gallery_link'=>'file','open_lightbox'=>'yes','gap'=>['unit'=>'px','size'=>12]]);}
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#FFFFFF','padding'=>$pp],$bx),[mk_col(100,[$gw])]);

// S9 WHY CHOOSE
$bxs=[['&#x1F33F; Guides Autochtones','Nos guides sont n&eacute;s ici. Ils connaissent chaque sentier, chaque plante, chaque histoire.'],['&#x1F91D; Impact Communautaire','Votre aventure finance directement les familles locales et la pr&eacute;servation culturelle.'],['&#x2B50; Exp&eacute;rience Unique','Aucune agence ne vous offrira cet acc&egrave;s. Nous vivons ici. Vous serez nos invit&eacute;s.']];
if($hf){$bw=array_map(fn($b)=>mk_widget('bdt-flip-box',['front_title_text'=>$b[0],'back_description_text'=>$b[1],'front_title_color'=>'#1a1a1a','back_description_color'=>'#FFFFFF','front_background_color'=>'#FFFFFF','back_background_color'=>'#2E7D32','border_radius'=>['unit'=>'px','top'=>8,'right'=>8,'bottom'=>8,'left'=>8,'isLinked'=>true]]),$bxs);}
else{$bw=array_map(fn($b)=>mk_widget('icon-box',['title_text'=>$b[0],'description_text'=>$b[1],'title_color'=>'#2E7D32','description_color'=>'#1a1a1a','align'=>'center']),$bxs);}
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#F7F9F4','padding'=>$pp],$bx),[
  mk_col(100,[mk_widget('heading',['title'=>'Pourquoi Choisir Ancestral Hike ?','align'=>'center','header_size'=>'h2','title_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>32]])]),
  mk_col(33,[$bw[0]]),mk_col(33,[$bw[1]]),mk_col(34,[$bw[2]]),
]);

// S10 TESTIMONIALS
$th='<div style="display:flex;gap:24px;flex-wrap:wrap;justify-content:center;"><div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);"><p style="color:#F9A825;font-size:18px;margin:0 0 12px;">&#9733;&#9733;&#9733;&#9733;&#9733;</p><p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Une exp&eacute;rience qui change la vie. Nos guides connaissaient chaque plante, chaque histoire. Je recommande &agrave; 100%.&rdquo;</p><p style="color:#2E7D32;font-weight:600;margin-top:16px;">&mdash; Marie L., France</p></div><div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);"><p style="color:#F9A825;font-size:18px;margin:0 0 12px;">&#9733;&#9733;&#9733;&#9733;&#9733;</p><p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Compl&egrave;tement diff&eacute;rent des tours classiques. On se sent vraiment accueillis par la communaut&eacute; locale.&rdquo;</p><p style="color:#2E7D32;font-weight:600;margin-top:16px;">&mdash; Thomas B., Belgique</p></div><div style="flex:1;min-width:260px;max-width:360px;background:#fff;padding:32px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.08);"><p style="color:#F9A825;font-size:18px;margin:0 0 12px;">&#9733;&#9733;&#9733;&#9733;&#9733;</p><p style="color:#1a1a1a;font-style:italic;line-height:1.7;">&ldquo;Les ruines de Bunkuany m&rsquo;ont coup&eacute; le souffle. Le guide Kogui &eacute;tait incroyable.&rdquo;</p><p style="color:#2E7D32;font-weight:600;margin-top:16px;">&mdash; Sophie M., Suisse</p></div></div>';
$page[]=mk_section(array_merge(['background_background'=>'classic','background_color'=>'#FFFFFF','padding'=>$pp],$bx),[mk_col(100,[
  mk_widget('heading',['title'=>'Ce que disent nos Voyageurs','align'=>'center','header_size'=>'h2','title_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>32]]),
  mk_widget('text-editor',['editor'=>$th]),
])]);

// S11 CTA
$page[]=mk_section(['background_background'=>'classic','background_color'=>'#1B5E20','padding'=>['unit'=>'px','top'=>'100','right'=>'30','bottom'=>'100','left'=>'30','isLinked'=>false],'content_position'=>'middle'],[mk_col(100,[
  mk_widget('heading',['title'=>'Pr&ecirc;t pour l\'Aventure ?','align'=>'center','header_size'=>'h2','title_color'=>'#FFFFFF','typography_typography'=>'custom','typography_font_size'=>['unit'=>'px','size'=>42]]),
  mk_widget('text-editor',['editor'=>'<p style="text-align:center;color:#FFFFFF;font-size:18px;line-height:1.8;">Rejoignez le prochain groupe. Places limit&eacute;es &agrave; 12 personnes.</p>']),
  mk_widget('button',['text'=>'R&eacute;server Maintenant','align'=>'center','size'=>'lg','border_radius'=>['unit'=>'px','top'=>50,'right'=>50,'bottom'=>50,'left'=>50,'isLinked'=>true],'background_color'=>'#FFFFFF','button_text_color'=>'#2E7D32','typography_typography'=>'custom','typography_font_weight'=>'700']),
  mk_widget('button',['text'=>'&#x1F4AC; WhatsApp','link'=>['url'=>'https://api.whatsapp.com/send?phone=573042233019','is_external'=>'on'],'align'=>'center','size'=>'lg','border_radius'=>['unit'=>'px','top'=>50,'right'=>50,'bottom'=>50,'left'=>50,'isLinked'=>true],'border_width'=>['unit'=>'px','top'=>2,'right'=>2,'bottom'=>2,'left'=>2,'isLinked'=>true],'border_color'=>'#FFFFFF','background_color'=>'rgba(0,0,0,0)','button_text_color'=>'#FFFFFF']),
],['content_position'=>'middle'])]);

// APPLY
$json=json_encode($page,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
update_post_meta(1788,'_elementor_data',wp_slash($json));
update_post_meta(1788,'_elementor_edit_mode','builder');
update_post_meta(1788,'_elementor_template_type','wp-page');
\Elementor\Plugin::$instance->files_manager->clear_cache();
echo "\nSUCCESS: ".count($page)." sections applied to post 1788\n";
echo "Images: $n | Gallery: ".($hg?'bdt-custom-gallery':'native')." | FlipBox: ".($hf?'bdt-flip-box':'icon-box')."\n";
echo "Preview: https://ancestralhike.com/?p=1788\n";
'@

$phpFile = "$env:TEMP\redesign_1788.php"
$PHP | Set-Content -Path $phpFile -Encoding utf8

# ── Upload PHP script ────────────────────────────────────────
Write-Host "-> Uploading PHP script..." -ForegroundColor Cyan
scp -i $KEY -P $PORT -o StrictHostKeyChecking=no $phpFile "${USER}@${HOST}:/tmp/redesign_1788.php"

# ── Run redesign ─────────────────────────────────────────────
Write-Host "-> Running redesign on server..." -ForegroundColor Cyan
SSH-Run "wp eval-file /tmp/redesign_1788.php --path=$WP_PATH"

# ── Flush & clean up ─────────────────────────────────────────
Write-Host "-> Flushing cache..." -ForegroundColor Cyan
SSH-Run "wp --path=$WP_PATH rewrite flush; wp --path=$WP_PATH cache flush 2>/dev/null; rm -f /tmp/redesign_1788.php"

Remove-Item $phpFile -ErrorAction SilentlyContinue
Remove-Item $KEY -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "DONE! Visit: https://ancestralhike.com/?p=1788" -ForegroundColor Green
Write-Host "Backup saved on server at: /tmp/backup_${POST}_${DATE}.json" -ForegroundColor Green
