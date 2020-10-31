#!/usr/bin/env python3

# Calculate placement coordinates of microphones.

from numpy import exp, abs, angle, pi

# Center of our board.
CENTER = 133.3 + 1j * 94.075
R = 46

def polar2z(r,theta):
    return r * exp( 1j * theta )

def z2polar(z):
    return ( abs(z), angle(z) )


def main():
    for i in range(16):
        r,a = z2polar(R)
        # KiCad has Y growing downwards, so revert rotation.
        a -= i * 2 * pi / 16
        p = polar2z(r,a) + CENTER
        a_deg = (a * 180) / pi
        print("mic%02d: rot %f: %f x %f" % (i, -a_deg, p.real, p.imag))
        print("PHM%02d: rot %f: %f x %f" % (i, -a_deg + 11.125, p.real, p.imag))

        # For ODAS configuration we don't need to handle CENTER
        r,a = z2polar(R / 1000) # In meters
        a = i * 2 * pi / 16
        p = polar2z(r,a)
        print("odas: mic%02d: %f, %f, %f" % (i, -p.real, p.imag, 0))

if __name__ == "__main__":
    main()
