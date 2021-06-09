import binascii
import time
import pygame.mixer

a = None
s = None
mx = None
psd = 0

pygame.mixer.init(frequency=44100)


def playsong():
    global a, s, mx, psd

    if mx is not None:
        mx.stop()

    print(f"Now Playing... assets/{a}{hex(s).replace('0x', '')}.wav")
    mx = pygame.mixer.Sound(f"assets/{a}{hex(s).replace('0x', '')}.wav")
    mx.play()

    psd = 0

def mainloop():
    global a, s, mx, psd

    with open("assets/comms.txt", 'rb') as f:
        icode = binascii.hexlify(f.read())
        if len(icode) > 0:
            iclass = int(chr(icode[0]), 16)
            isubclass = int(chr(icode[1]), 16)

    with open("assets/comms.txt", 'w') as f:
        f.write("")

    if len(icode) > 0:
        if iclass == 0:  # playback control codes
            if isubclass == 0:  # back
                if a is None:
                    a = 1
                    s = 1
                    playsong()
                else:
                    if s is None:
                        s = 1
                        playsong()
                    else:
                        if s > 1:
                            s = s - 1
                        playsong()

            if isubclass == 1:  # pause / play
                if psd != 0 and mx is not None:
                    pygame.mixer.unpause()
                    psd = 0
                elif mx is not None:
                    pygame.mixer.pause()
                    psd = 1

            if isubclass == 2:  # next
                if a is None:
                    a = 1
                    s = 1
                    playsong()
                else:
                    if s is None:
                        s = 1
                        playsong()
                    else:
                        if s < 12 or (a == 2 and s < 9) or (a == 6 and s < 2):
                            s = s + 1
                        playsong()

            if isubclass == 3:  # stop
                a = None
                s = None
                psd = 0

                if mx is not None:
                    mx.stop()
                    mx = None

        else:
            a = iclass
            if isubclass != 0:  # set and play song
                s = isubclass
                playsong()


while True:
    try:
        mainloop()
    except Exception as e:
        print(e)
    finally:
        time.sleep(0.001)
