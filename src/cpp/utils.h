#pragma once

void convCRLF(char * newLine, char * dest, char * src);
char * createMidiFile(const char * notation, const char * abcFileName, const char * midiFileName, int speed, int transpose, int melody, int chords);