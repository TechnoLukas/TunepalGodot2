#include "utils.h"
#include <string>
#include <stdlib.h>
#include <stdio.h>

extern "C" int tunePalEntry(int,char *argv[]);

void convCRLF(char * newLine, char * dest, char * src) {
    int c = 0, state = 0;
    char * finalDest;
    int howLong;

    finalDest = dest;
    howLong = strlen(newLine);

    while ((c = *src++) != '\0') {
        if (state == 0) /* Normal state */ {
            if (c == '\n') {
                strcpy(dest, newLine);
                dest += howLong;

            } else if (c == '\r') {
                strcpy(dest, newLine);
                dest += howLong;
                state = 1; /* Possibly start of \r\n */
            } else /* Normal character */ {
                * dest = c;
                dest++;
            }
        } else /* Previous was '\r' */ {
            state = 0;
            if (c != '\n') {
                if (c == '\r') /* Two \r in a row, output newline */ {
                    strcpy(dest, newLine);
                    dest += howLong;
                } else /* Normal character */ {
                    * dest = *src;
                    dest++;
                }
            }
        }
    }
    * dest = '\0';
}

char * createMidiFile(const char * notation, const char * abcFileName, const char * midiFileName, int speed, int transpose, int melody, int chords)
{
    char fixed[2048];


    convCRLF("\n", fixed, (char *) notation);

    const char * pastX = strstr(notation, "X:");
    if (pastX == NULL) {
        pastX = strstr(notation, "x:");
    }

    pastX = strstr(pastX, "\n");

    FILE * fp = fopen(abcFileName, "wb");
    if (fp == NULL)
    {
        return "ERROR: Could not open file";
    }
    int ret = fprintf(fp, "X:1\n");
    if (ret < 0)
    {
        return "ERROR: fprint returned negative value";
    }
    int midiNoteLength = (int) (30.0f + ( ((float)speed) / 9.0f) * 300.0f);
    fprintf(fp, "%%%%MIDI program %d\n", melody);
    fprintf(fp, "%%%%MIDI bassprog %d\n", chords);
    fprintf(fp, "%%%%MIDI transpose %d\n", transpose);
    fprintf(fp, "Q:1/4 = %d\n", midiNoteLength);

    ret = fprintf(fp, "%s", pastX + 1);
    if (ret < 0)
    {
        return "ERROR: fprint returned negative value";
    }

    fflush(fp);

    fclose(fp);

    char * argv[5];
    argv[0] = "abc2midi"; // Dummy value because we dont actually spawn the program
    argv[1] = (char *) abcFileName;
    argv[2] = "1";
    argv[3] = "-o";
    argv[4] = (char *) midiFileName;

    tunePalEntry(5, argv);

    static char retstr[2000];
    sprintf(retstr, "midiNoteLength = %d speed: %d, transpose = %d, melody= %d, chords = %d", midiNoteLength, speed, transpose, melody, chords);

    return retstr;
}