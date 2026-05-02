import json, os

THEME_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "theme.json")

DEFAULT = {
    "primary":   "#C9A84C",
    "bg":        "#0A0A0A",
    "card":      "#141414",
    "font_size": "Medium",
    "mode":      "Dark",
}

PRESETS = {
    "Dark Red": "#8B0000",
    "Gold":     "#C9A84C",
    "Amber":    "#E8A020",
    "Silver":   "#A8A8B0",
    "Green":    "#22B55A",
    "Blue":     "#2278E8",
}

BG_PRESETS = {
    "Black":  "#0A0A0A",
    "Navy":   "#0A0F1E",
    "Forest": "#0D1A0D",
    "Brown":  "#1A0A00",
}

LIGHT_BG_PRESETS = {
    "White":  "#F5F5F5",
    "Cream":  "#FAF6EE",
    "Grey":   "#E8E8E8",
    "Warm":   "#F5F0E8",
}

def _hex_color(h, a=1.0):
    try:
        h = h.lstrip("#")
        if len(h) == 3: h = "".join(c*2 for c in h)
        r,g,b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
        return (r/255, g/255, b/255, a)
    except:
        return (0.79, 0.66, 0.30, a)

def load_theme():
    try:
        with open(THEME_PATH, "r") as f:
            t = json.load(f)
            for k in DEFAULT:
                if k not in t: t[k] = DEFAULT[k]
            return t
    except:
        return DEFAULT.copy()

def save_theme(t):
    os.makedirs(os.path.dirname(THEME_PATH), exist_ok=True)
    with open(THEME_PATH, "w") as f:
        json.dump(t, f, indent=2)

class Theme:
    def __init__(self):
        self.reload()

    def reload(self):
        t = load_theme()
        self.primary     = _hex_color(t["primary"])
        self.primary_hex = t["primary"]
        self.bg          = _hex_color(t["bg"])
        self.bg_hex      = t["bg"]
        self.card        = _hex_color(t["card"])
        self.card_hex    = t["card"]
        self.font_size   = t["font_size"]
        self.mode        = t.get("mode", "Dark")

        r,g,b,_ = self.primary
        self.primary_dark  = (r*0.65, g*0.65, b*0.65, 1)
        self.primary_light = (min(r*1.25,1), min(g*1.25,1), min(b*1.25,1), 1)
        self.grad_start    = self.primary
        self.grad_end      = self.primary_dark
        self.gold_text     = (0.05, 0.05, 0.05, 1)

        rb,gb,bb,_ = self.bg
        self.card2      = (min(rb+0.06,1), min(gb+0.06,1), min(bb+0.06,1), 1)
        self.header_bg  = (min(rb+0.04,1), min(gb+0.04,1), min(bb+0.04,1), 1)
        self.input_bg   = (min(rb+0.08,1), min(gb+0.08,1), min(bb+0.08,1), 1)

        fs = {"Small":0.85, "Medium":1.0, "Large":1.2}
        m  = fs.get(self.font_size, 1.0)
        self.fs_small  = int(12*m)
        self.fs_normal = int(14*m)
        self.fs_large  = int(17*m)
        self.fs_title  = int(22*m)

        # Fixed colors
        self.white    = (1,1,1,1)
        self.white70  = (1,1,1,0.70)
        self.white40  = (1,1,1,0.40)
        self.grey     = (0.55,0.55,0.55,1)
        self.red      = (0.85,0.20,0.20,1)
        self.green    = (0.15,0.70,0.35,1)
        self.blue     = (0.20,0.50,0.90,1)
        self.hot      = (0.90,0.35,0.15,1)
        self.iced     = (0.20,0.60,0.95,1)
        self.fav      = (0.95,0.78,0.20,1)
        self.divider  = (0.20,0.20,0.20,1)
        self.border   = (0.25,0.22,0.12,1)

        if self.mode == "Light":
            self.text_main = (0.05, 0.05, 0.05, 1)
            self.white     = (0.05, 0.05, 0.05, 1)
            self.white70   = (0.1, 0.1, 0.1, 0.85)
            self.white40   = (0.1, 0.1, 0.1, 0.55)
            self.grey      = (0.35, 0.35, 0.35, 1)
            self.divider   = (0.75, 0.75, 0.75, 1)
        else:
            self.text_main = (1,1,1,1)
            
        # Bold & Modern design tokens
        self.radius_sm   = [8]
        self.radius_md   = [12]
        self.radius_lg   = [18]
        self.spacing_xs  = 4
        self.spacing_sm  = 8
        self.spacing_md  = 16
        self.spacing_lg  = 24
        self.btn_height  = 52
        self.card_border = (0.55, 0.0, 0.0, 0.6)
TH = Theme()

def reload_theme():
    global TH
    TH.__init__()