import time
from tkinter import Label, Tk


def gui() -> None:
    root = Tk()
    root.title("Simple Clock")
    root.geometry("200x50")
    root.resizable(False, False)

    label = Label(root, font=("Arial", 30), bg="black", fg="white")
    label.pack(pady=20)

    def update_clock() -> None:
        current_time = time.strftime("%H:%M:%S")
        label.config(text=current_time)
        label.after(1000, update_clock)
        return

    update_clock()
    root.mainloop()


if __name__ == "__main__":
    gui()
