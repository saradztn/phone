import sys
import os
import ctypes
import threading
import time
import json
import tkinter as tk
from tkinter import ttk, messagebox
import keyboard
from ctypes import wintypes, windll, Structure, byref, c_int

# ============================================
# Raw Input Setup
# ============================================
user32 = windll.user32
kernel32 = windll.kernel32

class POINT(Structure):
    _fields_ = [("x", c_int), ("y", c_int)]

# Constants
MOUSEEVENTF_MOVE = 0x0001

# ============================================
# صلاحيات المسؤول
# ============================================
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def run_as_admin():
    if not is_admin():
        print("[*] إعادة التشغيل كمسؤول...")
        ctypes.windll.shell32.ShellExecuteW(
            None, "runas", sys.executable,
            f'"{os.path.abspath(__file__)}"',
            None, 1
        )
        sys.exit(0)

# ============================================
# محرك إزالة التحركات الزائدة + حدود الضغط
# ============================================
class MouseMovementFilter:
    def __init__(self):
        self.filter_enabled = False
        self.monitor_enabled = True
        self.recording = False
        self.recording_direction = None
        
        # حدود الحركة الصغيرة (Dead Zone)
        self.thresholds = {
            "up": 0.0,
            "down": 0.0,
            "left": 0.0,
            "right": 0.0,
            "up_left": 0.0,
            "up_right": 0.0,
            "down_left": 0.0,
            "down_right": 0.0
        }
        
        # حدود الحركة القصوى أثناء الضغط على الزر الأيسر
        self.click_limits_enabled = False
        self.click_limits = {
            "up": 0,      # 0 = غير محدود
            "down": 0,
            "left": 0,
            "right": 0
        }
        
        # متتبع الحركة المتراكمة أثناء الضغط
        self.accumulated_movement = {
            "up": 0.0,
            "down": 0.0,
            "left": 0.0,
            "right": 0.0
        }
        
        self.left_button_pressed = False
        self.recorded_value = 0.0
        self.lock = threading.Lock()
        self.monitor_thread = None
        
        self.mouse_event = user32.mouse_event
        self.mouse_event.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.DWORD, wintypes.DWORD, wintypes.LPARAM]
        
        self.config_file = "mouse_filter_config.json"
        self.start_monitor()

    def get_cursor_pos(self):
        pt = POINT()
        user32.GetCursorPos(byref(pt))
        return pt.x, pt.y

    def move_mouse_raw(self, dx, dy):
        if dx == 0 and dy == 0:
            return
        self.mouse_event(MOUSEEVENTF_MOVE, int(dx), int(dy), 0, 0)

    def is_left_button_pressed(self):
        """التحقق من حالة الزر الأيسر"""
        return user32.GetAsyncKeyState(0x01) & 0x8000 != 0

    def reset_accumulated_movement(self):
        """إعادة تعيين الحركة المتراكمة"""
        with self.lock:
            self.accumulated_movement = {
                "up": 0.0,
                "down": 0.0,
                "left": 0.0,
                "right": 0.0
            }

    def start_recording(self, direction):
        with self.lock:
            self.recording = True
            self.recording_direction = direction
            self.recorded_value = 0.0
        print(f"[+] بدء التسجيل: {direction}")

    def stop_recording(self):
        with self.lock:
            if self.recording and self.recording_direction:
                final_value = abs(self.recorded_value)
                direction = self.recording_direction
                
                if final_value > 0:
                    self.thresholds[direction] = final_value
                    print(f"[✓] تم حفظ: {direction} = {final_value:.1f} بكسل")
                else:
                    print(f"[!] لم يتم تسجيل حركة في {direction}")
                
                self.recording = False
                self.recording_direction = None
                self.recorded_value = 0.0
                
                return final_value
            
            return 0.0

    def cancel_recording(self):
        with self.lock:
            self.recording = False
            self.recording_direction = None
            self.recorded_value = 0.0
        print("[-] تم إلغاء التسجيل")

    def monitor_loop(self):
        print("[+] Monitor Started (8 Directions + Click Limits)!")
        
        last_x, last_y = self.get_cursor_pos()
        
        while self.monitor_enabled:
            try:
                current_x, current_y = self.get_cursor_pos()
                
                dx = current_x - last_x
                dy = current_y - last_y
                
                # مراقبة حالة الزر الأيسر
                current_left_state = self.is_left_button_pressed()
                
                # عند بداية الضغط - إعادة تعيين العداد
                if current_left_state and not self.left_button_pressed:
                    self.reset_accumulated_movement()
                    print("[🖱️] بدء الضغط - إعادة تعيين الحدود")
                
                self.left_button_pressed = current_left_state
                
                if dx == 0 and dy == 0:
                    time.sleep(0.001)
                    continue
                
                # ============================================
                # وضع التسجيل
                # ============================================
                if self.recording:
                    direction = self.recording_direction
                    
                    with self.lock:
                        if direction == "up" and dy < 0 and abs(dy) > abs(dx):
                            self.recorded_value += abs(dy)
                            print(f"[📊] فوق: {self.recorded_value:.1f} px")
                        
                        elif direction == "down" and dy > 0 and abs(dy) > abs(dx):
                            self.recorded_value += abs(dy)
                            print(f"[📊] تحت: {self.recorded_value:.1f} px")
                        
                        elif direction == "left" and dx < 0 and abs(dx) > abs(dy):
                            self.recorded_value += abs(dx)
                            print(f"[📊] يسار: {self.recorded_value:.1f} px")
                        
                        elif direction == "right" and dx > 0 and abs(dx) > abs(dy):
                            self.recorded_value += abs(dx)
                            print(f"[📊] يمين: {self.recorded_value:.1f} px")
                        
                        elif direction == "up_left" and dy < 0 and dx < 0:
                            distance = (dx**2 + dy**2)**0.5
                            self.recorded_value += distance
                            print(f"[📊] فوق-يسار: {self.recorded_value:.1f} px")
                        
                        elif direction == "up_right" and dy < 0 and dx > 0:
                            distance = (dx**2 + dy**2)**0.5
                            self.recorded_value += distance
                            print(f"[📊] فوق-يمين: {self.recorded_value:.1f} px")
                        
                        elif direction == "down_left" and dy > 0 and dx < 0:
                            distance = (dx**2 + dy**2)**0.5
                            self.recorded_value += distance
                            print(f"[📊] تحت-يسار: {self.recorded_value:.1f} px")
                        
                        elif direction == "down_right" and dy > 0 and dx > 0:
                            distance = (dx**2 + dy**2)**0.5
                            self.recorded_value += distance
                            print(f"[📊] تحت-يمين: {self.recorded_value:.1f} px")
                    
                    last_x, last_y = current_x, current_y
                    time.sleep(0.001)
                    continue
                
                # ============================================
                # وضع الحدود أثناء الضغط (له الأولوية)
                # ============================================
                if self.click_limits_enabled and self.left_button_pressed:
                    with self.lock:
                        cancel_x = 0
                        cancel_y = 0
                        
                        # فحص الحد الأقصى للحركة الأفقية
                        if dx > 0:  # يمين
                            self.accumulated_movement["right"] += dx
                            if self.click_limits["right"] > 0:
                                if self.accumulated_movement["right"] > self.click_limits["right"]:
                                    # تجاوز الحد - إلغاء الزائد
                                    excess = self.accumulated_movement["right"] - self.click_limits["right"]
                                    cancel_x = -excess
                                    self.accumulated_movement["right"] = self.click_limits["right"]
                                    print(f"[⛔] حد اليمين: {self.click_limits['right']} px")
                        
                        elif dx < 0:  # يسار
                            self.accumulated_movement["left"] += abs(dx)
                            if self.click_limits["left"] > 0:
                                if self.accumulated_movement["left"] > self.click_limits["left"]:
                                    excess = self.accumulated_movement["left"] - self.click_limits["left"]
                                    cancel_x = excess
                                    self.accumulated_movement["left"] = self.click_limits["left"]
                                    print(f"[⛔] حد اليسار: {self.click_limits['left']} px")
                        
                        # فحص الحد الأقصى للحركة العمودية
                        if dy > 0:  # تحت
                            self.accumulated_movement["down"] += dy
                            if self.click_limits["down"] > 0:
                                if self.accumulated_movement["down"] > self.click_limits["down"]:
                                    excess = self.accumulated_movement["down"] - self.click_limits["down"]
                                    cancel_y = -excess
                                    self.accumulated_movement["down"] = self.click_limits["down"]
                                    print(f"[⛔] حد الأسفل: {self.click_limits['down']} px")
                        
                        elif dy < 0:  # فوق
                            self.accumulated_movement["up"] += abs(dy)
                            if self.click_limits["up"] > 0:
                                if self.accumulated_movement["up"] > self.click_limits["up"]:
                                    excess = self.accumulated_movement["up"] - self.click_limits["up"]
                                    cancel_y = excess
                                    self.accumulated_movement["up"] = self.click_limits["up"]
                                    print(f"[⛔] حد الأعلى: {self.click_limits['up']} px")
                        
                        # تطبيق الإلغاء
                        if cancel_x != 0 or cancel_y != 0:
                            self.move_mouse_raw(cancel_x, cancel_y)
                            last_x, last_y = self.get_cursor_pos()
                            time.sleep(0.001)
                            continue
                
                # ============================================
                # وضع التصفية العادي (Dead Zone)
                # ============================================
                if self.filter_enabled and not self.left_button_pressed:
                    with self.lock:
                        cancel_x = 0
                        cancel_y = 0
                        
                        is_diagonal = abs(dx) > 0 and abs(dy) > 0
                        
                        if is_diagonal:
                            distance = (dx**2 + dy**2)**0.5
                            
                            if dy < 0 and dx < 0:
                                if self.thresholds["up_left"] > 0 and distance <= self.thresholds["up_left"]:
                                    cancel_x = -dx
                                    cancel_y = -dy
                            
                            elif dy < 0 and dx > 0:
                                if self.thresholds["up_right"] > 0 and distance <= self.thresholds["up_right"]:
                                    cancel_x = -dx
                                    cancel_y = -dy
                            
                            elif dy > 0 and dx < 0:
                                if self.thresholds["down_left"] > 0 and distance <= self.thresholds["down_left"]:
                                    cancel_x = -dx
                                    cancel_y = -dy
                            
                            elif dy > 0 and dx > 0:
                                if self.thresholds["down_right"] > 0 and distance <= self.thresholds["down_right"]:
                                    cancel_x = -dx
                                    cancel_y = -dy
                        
                        else:
                            if dx > 0 and self.thresholds["right"] > 0:
                                if abs(dx) <= self.thresholds["right"]:
                                    cancel_x = -dx
                            
                            elif dx < 0 and self.thresholds["left"] > 0:
                                if abs(dx) <= self.thresholds["left"]:
                                    cancel_x = -dx
                            
                            if dy > 0 and self.thresholds["down"] > 0:
                                if abs(dy) <= self.thresholds["down"]:
                                    cancel_y = -dy
                            
                            elif dy < 0 and self.thresholds["up"] > 0:
                                if abs(dy) <= self.thresholds["up"]:
                                    cancel_y = -dy
                        
                        if cancel_x != 0 or cancel_y != 0:
                            self.move_mouse_raw(cancel_x, cancel_y)
                
                last_x, last_y = self.get_cursor_pos()
                time.sleep(0.001)
                
            except Exception as e:
                print(f"[!] خطأ: {e}")
                time.sleep(0.01)
        
        print("[-] Monitor Stopped")

    def start_monitor(self):
        if self.monitor_thread and self.monitor_thread.is_alive():
            return
        
        self.monitor_enabled = True
        self.monitor_thread = threading.Thread(target=self.monitor_loop, daemon=True)
        self.monitor_thread.start()

    def stop_monitor(self):
        self.monitor_enabled = False
        if self.monitor_thread and self.monitor_thread.is_alive():
            self.monitor_thread.join(timeout=1)

    def enable_filter(self):
        self.filter_enabled = True
        print("[+] الفلتر مفعّل!")

    def disable_filter(self):
        self.filter_enabled = False
        print("[-] الفلتر معطّل")

    def enable_click_limits(self):
        self.click_limits_enabled = True
        print("[+] حدود الضغط مفعّلة!")

    def disable_click_limits(self):
        self.click_limits_enabled = False
        print("[-] حدود الضغط معطّلة")

    def save_config(self):
        try:
            config = {
                "thresholds": self.thresholds,
                "click_limits": self.click_limits,
                "click_limits_enabled": self.click_limits_enabled
            }
            with open(self.config_file, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=4)
            print("[✓] تم حفظ الإعدادات")
            return True
        except Exception as e:
            print(f"[!] خطأ في الحفظ: {e}")
            return False

    def load_config(self):
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, "r", encoding="utf-8") as f:
                    config = json.load(f)
                    if "thresholds" in config:
                        self.thresholds.update(config["thresholds"])
                    if "click_limits" in config:
                        self.click_limits.update(config["click_limits"])
                    if "click_limits_enabled" in config:
                        self.click_limits_enabled = config["click_limits_enabled"]
                print("[✓] تم تحميل الإعدادات")
                return True
        except Exception as e:
            print(f"[!] خطأ في التحميل: {e}")
        return False

    def reset_all(self):
        with self.lock:
            self.thresholds = {
                "up": 0.0, "down": 0.0, "left": 0.0, "right": 0.0,
                "up_left": 0.0, "up_right": 0.0, "down_left": 0.0, "down_right": 0.0
            }
            self.click_limits = {"up": 0, "down": 0, "left": 0, "right": 0}
        print("[✓] تم إعادة تعيين جميع القيم")


# ============================================
# واجهة المستخدم
# ============================================
class MouseFilterGUI:
    def __init__(self, root):
        self.root = root
        self.filter = MouseMovementFilter()
        self.filter.load_config()
        
        self.setup_window()
        self.setup_ui()
        self.start_hotkey_listener()
        self.update_display()

    def setup_window(self):
        self.root.title("🎯 مزيل التحركات الزائدة + حدود الضغط")
        self.root.geometry("680x1000")
        self.root.configure(bg="#0a0e27")
        self.root.resizable(False, False)
        self.root.attributes("-topmost", True)
        self.root.attributes("-alpha", 0.96)

    def setup_ui(self):
        # الهيدر
        header = tk.Frame(self.root, bg="#00d9ff", pady=18)
        header.pack(fill="x")

        tk.Label(
            header,
            text="🎯 مزيل التحركات + حدود الضغط",
            font=("Arial Black", 18, "bold"),
            fg="white",
            bg="#00d9ff",
        ).pack()

        tk.Label(
            header,
            text="Dead Zone + Click Movement Limiter",
            font=("Arial", 10),
            fg="#0a0e27",
            bg="#00d9ff",
        ).pack()

        # حالة النظام
        status_frame = tk.Frame(self.root, bg="#0a0e27", pady=12)
        status_frame.pack()

        self.status_label = tk.Label(
            status_frame,
            text="⭕ الفلتر متوقف",
            font=("Arial", 15, "bold"),
            fg="#ff2e63",
            bg="#0a0e27",
        )
        self.status_label.pack()

        # أزرار التشغيل
        toggle_frame = tk.Frame(self.root, bg="#0a0e27")
        toggle_frame.pack(pady=8)

        self.toggle_btn = tk.Button(
            toggle_frame,
            text="▶  تشغيل Dead Zone",
            font=("Arial", 11, "bold"),
            fg="white",
            bg="#00ff88",
            activebackground="#00d9ff",
            width=18, height=2,
            relief="flat",
            cursor="hand2",
            command=self.toggle_filter,
        )
        self.toggle_btn.pack(side="left", padx=5)

        self.toggle_limits_btn = tk.Button(
            toggle_frame,
            text="▶  تشغيل حدود الضغط",
            font=("Arial", 11, "bold"),
            fg="white",
            bg="#ff9800",
            activebackground="#ffb74d",
            width=18, height=2,
            relief="flat",
            cursor="hand2",
            command=self.toggle_click_limits,
        )
        self.toggle_limits_btn.pack(side="left", padx=5)

        # ============================================
        # قسم Dead Zone (كود قديم)
        # ============================================
        deadzone_frame = tk.LabelFrame(
            self.root,
            text="  🎮 Dead Zone - إزالة الحركات الصغيرة  ",
            font=("Arial", 10, "bold"),
            fg="#00d9ff",
            bg="#1a1f3a",
            bd=2,
        )
        deadzone_frame.pack(fill="both", padx=15, pady=8, expand=False)

        # شبكة 3x3 مصغرة
        grid_container = tk.Frame(deadzone_frame, bg="#1a1f3a")
        grid_container.pack(pady=12, padx=15)

        # صف 1
        row1 = tk.Frame(grid_container, bg="#1a1f3a")
        row1.grid(row=0, column=0, columnspan=3, pady=3)

        self.up_left_btn = tk.Button(row1, text="↖️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("up_left"))
        self.up_left_btn.pack(side="left", padx=2)

        self.up_btn = tk.Button(row1, text="⬆️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("up"))
        self.up_btn.pack(side="left", padx=2)

        self.up_right_btn = tk.Button(row1, text="↗️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("up_right"))
        self.up_right_btn.pack(side="left", padx=2)

        # صف 2
        row2 = tk.Frame(grid_container, bg="#1a1f3a")
        row2.grid(row=1, column=0, columnspan=3, pady=3)

        self.left_btn = tk.Button(row2, text="⬅️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("left"))
        self.left_btn.pack(side="left", padx=2)

        center_info = tk.Frame(row2, bg="#0a0e27", width=80, height=50, relief="solid", bd=1)
        center_info.pack(side="left", padx=2)
        center_info.pack_propagate(False)
        
        self.recording_label = tk.Label(center_info, text="⚪", font=("Arial", 9, "bold"), fg="#ffeb3b", bg="#0a0e27")
        self.recording_label.pack(expand=True)

        self.right_btn = tk.Button(row2, text="➡️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("right"))
        self.right_btn.pack(side="left", padx=2)

        # صف 3
        row3 = tk.Frame(grid_container, bg="#1a1f3a")
        row3.grid(row=2, column=0, columnspan=3, pady=3)

        self.down_left_btn = tk.Button(row3, text="↙️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("down_left"))
        self.down_left_btn.pack(side="left", padx=2)

        self.down_btn = tk.Button(row3, text="⬇️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("down"))
        self.down_btn.pack(side="left", padx=2)

        self.down_right_btn = tk.Button(row3, text="↘️\n0", font=("Arial", 8, "bold"), fg="white", bg="#252a48", width=9, height=2, relief="flat", cursor="hand2", command=lambda: self.start_recording("down_right"))
        self.down_right_btn.pack(side="left", padx=2)

        # ============================================
        # قسم حدود الضغط (جديد)
        # ============================================
        limits_frame = tk.LabelFrame(
            self.root,
            text="  🖱️ حدود الحركة أثناء الضغط على الزر الأيسر  ",
            font=("Arial", 10, "bold"),
            fg="#ff9800",
            bg="#1a1f3a",
            bd=2,
        )
        limits_frame.pack(fill="both", padx=15, pady=8, expand=True)

        tk.Label(
            limits_frame,
            text="💡 أدخل الحد الأقصى للحركة (بكسل) | 0 = غير محدود",
            font=("Arial", 9),
            fg="#aaa",
            bg="#1a1f3a"
        ).pack(pady=5)

        # حقول الإدخال
        inputs_container = tk.Frame(limits_frame, bg="#1a1f3a")
        inputs_container.pack(pady=10, padx=20, fill="both")

        self.limit_entries = {}
        
        # فوق
        self.create_limit_input(inputs_container, "⬆️ فوق (Up)", "up", 0)
        
        # تحت
        self.create_limit_input(inputs_container, "⬇️ تحت (Down)", "down", 1)
        
        # يسار
        self.create_limit_input(inputs_container, "⬅️ يسار (Left)", "left", 2)
        
        # يمين
        self.create_limit_input(inputs_container, "➡️ يمين (Right)", "right", 3)

        # زر تطبيق الحدود
        apply_btn = tk.Button(
            limits_frame,
            text="✅ تطبيق الحدود",
            font=("Arial", 11, "bold"),
            fg="white",
            bg="#4caf50",
            activebackground="#66bb6a",
            width=20, height=2,
            relief="flat",
            cursor="hand2",
            command=self.apply_click_limits,
        )
        apply_btn.pack(pady=10)

        # عرض الحدود الحالية
        self.limits_display = tk.Label(
            limits_frame,
            text="الحدود الحالية: لا يوجد",
            font=("Arial", 9),
            fg="#ffeb3b",
            bg="#1a1f3a"
        )
        self.limits_display.pack(pady=5)

        # أزرار التحكم
        control_frame = tk.Frame(self.root, bg="#0a0e27")
        control_frame.pack(pady=12)

        tk.Button(
            control_frame,
            text="💾 حفظ للأبد",
            font=("Arial", 11, "bold"),
            fg="white",
            bg="#00ff88",
            activebackground="#00d9ff",
            width=13, height=2,
            relief="flat",
            cursor="hand2",
            command=self.save_forever,
        ).pack(side="left", padx=4)

        tk.Button(
            control_frame,
            text="🔄 إعادة تعيين",
            font=("Arial", 11, "bold"),
            fg="white",
            bg="#ff2e63",
            activebackground="#ff5588",
            width=13, height=2,
            relief="flat",
            cursor="hand2",
            command=self.reset_all,
        ).pack(side="left", padx=4)

        # الاختصارات
        hotkeys = tk.Frame(self.root, bg="#252a48", pady=8)
        hotkeys.pack(fill="x", pady=5)
        
        tk.Label(
            hotkeys,
            text="⌨️ F8: Dead Zone | F9: حدود الضغط | Enter: حفظ تسجيل | Esc: إلغاء",
            font=("Arial", 8, "bold"),
            fg="#aaa",
            bg="#252a48"
        ).pack()

        # تحديث العرض
        self.update_limits_display()

    def create_limit_input(self, parent, label_text, direction, row):
        """إنشاء حقل إدخال لحد معين"""
        frame = tk.Frame(parent, bg="#252a48", relief="solid", bd=1)
        frame.pack(fill="x", pady=5, padx=10)

        tk.Label(
            frame,
            text=label_text,
            font=("Arial", 10, "bold"),
            fg="white",
            bg="#252a48",
            width=15,
            anchor="w"
        ).pack(side="left", padx=10, pady=8)

        entry = tk.Entry(
            frame,
            font=("Arial", 11),
            width=10,
            bg="#0a0e27",
            fg="white",
            insertbackground="white",
            relief="flat",
            bd=0,
            justify="center"
        )
        entry.pack(side="left", padx=10, pady=5)
        entry.insert(0, str(self.filter.click_limits[direction]))
        
        self.limit_entries[direction] = entry

        tk.Label(
            frame,
            text="بكسل",
            font=("Arial", 9),
            fg="#888",
            bg="#252a48"
        ).pack(side="left", padx=5)

    def apply_click_limits(self):
        """تطبيق الحدود من حقول الإدخال"""
        try:
            with self.filter.lock:
                for direction, entry in self.limit_entries.items():
                    value = entry.get().strip()
                    if value == "" or value == "0":
                        self.filter.click_limits[direction] = 0
                    else:
                        self.filter.click_limits[direction] = int(value)
            
            self.update_limits_display()
            messagebox.showinfo("✅", "تم تطبيق الحدود بنجاح!")
            
        except ValueError:
            messagebox.showerror("❌", "أدخل أرقاماً صحيحة فقط!")

    def update_limits_display(self):
        """تحديث عرض الحدود الحالية"""
        active = []
        for direction, value in self.filter.click_limits.items():
            if value > 0:
                icons = {"up": "⬆️", "down": "⬇️", "left": "⬅️", "right": "➡️"}
                active.append(f"{icons[direction]} {value}px")
        
        if active:
            text = "الحدود: " + " | ".join(active)
        else:
            text = "الحدود: غير محدود (كل الاتجاهات)"
        
        self.limits_display.config(text=text)

    def start_recording(self, direction):
        if self.filter.recording:
            messagebox.showwarning("⚠️", "جاري التسجيل!")
            return
        
        self.filter.start_recording(direction)
        self.recording_label.config(text=f"🔴", fg="#ff2e63")
        self.highlight_active_button(direction, True)
        self.update_recording_value()

    def update_recording_value(self):
        if self.filter.recording:
            value = self.filter.recorded_value
            self.recording_label.config(text=f"🔴\n{value:.0f}")
            self.root.after(50, self.update_recording_value)

    def finish_recording(self):
        if not self.filter.recording:
            return
        
        direction = self.filter.recording_direction
        value = self.filter.stop_recording()
        
        if value > 0:
            self.recording_label.config(text=f"✅\n{value:.0f}", fg="#00ff88")
            self.update_display()
            self.highlight_active_button(direction, False)
            
            self.root.after(1000, lambda: self.recording_label.config(text="⚪", fg="#ffeb3b"))
        else:
            messagebox.showwarning("⚠️", "لم يتم تسجيل حركة!")
            self.cancel_recording()

    def cancel_recording(self):
        if self.filter.recording:
            direction = self.filter.recording_direction
            self.filter.cancel_recording()
            self.recording_label.config(text="❌", fg="#ff9800")
            self.highlight_active_button(direction, False)
            self.root.after(800, lambda: self.recording_label.config(text="⚪", fg="#ffeb3b"))

    def highlight_active_button(self, direction, active):
        buttons = {
            "up": self.up_btn, "down": self.down_btn,
            "left": self.left_btn, "right": self.right_btn,
            "up_left": self.up_left_btn, "up_right": self.up_right_btn,
            "down_left": self.down_left_btn, "down_right": self.down_right_btn
        }
        
        if direction in buttons:
            buttons[direction].config(
                bg="#ff2e63" if active else "#252a48",
                relief="solid" if active else "flat"
            )

    def update_display(self):
        data = {
            "up": ("⬆️", self.up_btn), "down": ("⬇️", self.down_btn),
            "left": ("⬅️", self.left_btn), "right": ("➡️", self.right_btn),
            "up_left": ("↖️", self.up_left_btn), "up_right": ("↗️", self.up_right_btn),
            "down_left": ("↙️", self.down_left_btn), "down_right": ("↘️", self.down_right_btn)
        }
        
        for direction, (icon, button) in data.items():
            value = self.filter.thresholds[direction]
            color = "#00ff88" if value > 0 else "#252a48"
            button.config(text=f"{icon}\n{value:.0f}", bg=color)

    def toggle_filter(self):
        if self.filter.filter_enabled:
            self.filter.disable_filter()
            self.status_label.config(text="⭕ Dead Zone متوقف", fg="#ff2e63")
            self.toggle_btn.config(text="▶  تشغيل Dead Zone", bg="#00ff88")
        else:
            self.filter.enable_filter()
            self.status_label.config(text="✅ Dead Zone يعمل", fg="#00ff88")
            self.toggle_btn.config(text="⏹  إيقاف Dead Zone", bg="#ff2e63")

    def toggle_click_limits(self):
        if self.filter.click_limits_enabled:
            self.filter.disable_click_limits()
            self.toggle_limits_btn.config(text="▶  تشغيل حدود الضغط", bg="#ff9800")
        else:
            # التحقق من وجود حدود
            if all(v == 0 for v in self.filter.click_limits.values()):
                messagebox.showinfo("💡", "قم بإدخال الحدود أولاً ثم اضغط 'تطبيق الحدود'")
                return
            
            self.filter.enable_click_limits()
            self.toggle_limits_btn.config(text="⏹  إيقاف حدود الضغط", bg="#4caf50")

    def save_forever(self):
        if self.filter.save_config():
            messagebox.showinfo("✅", "تم حفظ جميع الإعدادات بنجاح!")
        else:
            messagebox.showerror("❌", "فشل الحفظ!")

    def reset_all(self):
        if messagebox.askyesno("🔄", "إعادة تعيين كل شيء؟"):
            self.filter.reset_all()
            self.update_display()
            for entry in self.limit_entries.values():
                entry.delete(0, tk.END)
                entry.insert(0, "0")
            self.update_limits_display()
            messagebox.showinfo("✅", "تم!")

    def start_hotkey_listener(self):
        def listen():
            try:
                keyboard.add_hotkey("F8", self.toggle_filter)
                keyboard.add_hotkey("F9", self.toggle_click_limits)
                keyboard.add_hotkey("enter", self.finish_recording)
                keyboard.add_hotkey("esc", self.cancel_recording)
                keyboard.wait()
            except:
                pass
        
        threading.Thread(target=listen, daemon=True).start()

    def on_close(self):
        self.filter.stop_monitor()
        self.root.destroy()


if __name__ == "__main__":
    run_as_admin()
    root = tk.Tk()
    app = MouseFilterGUI(root)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()
