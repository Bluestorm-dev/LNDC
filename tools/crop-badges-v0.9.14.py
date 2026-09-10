"""Le Nid des Champions V0.9.14 — géométrie de découpe des 100 succès.

Les planches sources 1672x941 ne sont pas distribuées dans le ZIP. La release
utilise un crop 320x320 puis un masque de contour afin de supprimer titres et
libellés et d'obtenir un PNG transparent 512x512.
"""
X_CENTERS = [180, 507, 836, 1165, 1492]
Y_STARTS = [160, 510]
CROP_SIZE = 320
OUTPUT_SIZE = 512
THRESHOLD_BY_RARITY = {"common": 60, "rare": 60, "epic": 50, "legendary": 60, "secret": 45}
