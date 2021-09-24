# correr con Python 2.7
# total_words = words_per_line * number_of_lines
def singleWordPerLine2newFormat(words_per_line, number_of_lines, name_file_in, name_file_out):
    fr = open(name_file_in, 'r')
    fw = open(name_file_out,'w')
    new_line = range(words_per_line)
    for i in range(number_of_lines):
        for j in range(words_per_line):
            new_line[words_per_line-1-j] = fr.read(8)
            if(new_line[words_per_line-1-j]==''):
                new_line[words_per_line-1-j] = '00000000'
            fr.read(1)
        for j in range(words_per_line):
            fw.write(new_line[j])
        fw.write('\n')
    fr.close()
    fw.close()
# 3906 lineas de 4 palabras => total_words = 3906*4 = 15624
singleWordPerLine2newFormat(4, 3906, "text_in", "text_in_formatted")
singleWordPerLine2newFormat(4, 3906, "data_in", "data_in_formatted")
