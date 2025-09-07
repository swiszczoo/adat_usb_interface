#!/usr/bin/python
import os
import random

# Protocol info taken from https://ackspace.nl/wiki/ADAT_project
NUM_FRAMES = 8

data_length = NUM_FRAMES * 256
bitset_adat = []
bitset_i2s = []

dir = os.path.dirname(os.path.abspath(__file__))

def bitfield(n):
    return [1 if digit=='1' else 0 for digit in format(n, '#034b')[2:]] # [2:] to chop off the "0b" part

def bits_to_bytes(bits):
    """Convert a list of bits (0/1) to a bytes object."""
    if len(bits) % 8 != 0:
        raise ValueError("Number of bits must be a multiple of 8")
    
    out = bytearray()
    for i in range(0, len(bits), 8):
        byte = 0
        for bit in bits[i:i+8]:
            byte = (byte << 1) | bit
        out.append(byte)
    return bytes(out)


if __name__ == '__main__':
    for frame in range(NUM_FRAMES):
        for sample in range(8):
            sample = random.randint(0, 2 ** 24 - 1)
            sample_bits = bitfield(sample)[-24:]

            bitset_adat += [1] + sample_bits[-24:-20] + [1] + sample_bits[-20:-16] + [1] + sample_bits[-16:-12] + [1] + sample_bits[-12:-8] + [1] + sample_bits[-8:-4] + [1] + sample_bits[-4:]
            bitset_i2s += sample_bits + ([0] * 8)

        bitset_adat += [1,0,0,0,0,0,0,0,0,0,0,1]
        user_bits = 15 - frame
        bitset_adat += bitfield(user_bits)[-4:]

    with open(dir + '/../tb/adat_test_data_adat.bin', 'wb') as out:
        out.write(bits_to_bytes(bitset_adat))

    with open(dir + '/../tb/adat_test_data_i2s.bin', 'wb') as out:
        out.write(bits_to_bytes(bitset_i2s))

    bitset_nrzi = []
    state = 1
    for i in range(len(bitset_adat)):
        if (bitset_adat[i] == 1):
            state = 1 if state == 0 else 0
        
        bitset_nrzi.append(state)

    with open(dir + '/../tb/adat_test_data_adat_nrzi.bin', 'wb') as out:
        out.write(bits_to_bytes(bitset_nrzi))
