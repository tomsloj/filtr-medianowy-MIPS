.data
	welcomeMessage: .asciiz "Start programu\n"
	endMessage: .asciiz "Koniec działania programu\n"
	errorMessage: .asciiz "Nie udało się otworzyć pliku\n"
	inputFileName: .asciiz "tmp1.bmp"
	outputFileName: .asciiz "out.bmp"
	enter: .asciiz "\n"
	space: .asciiz " "
	
	
	.align 2 # albo 4? czy w ogóle to powinno tu być? no ale inaczej nie działa więc może tak
	sizeBuffor: .space 4
	reservedBuffor: .space 4
	offsetBuffor: .space 4
	buffor: .space 4
	headerBuffor: .space 4
	widthBuffer: .space 4
	heightBuffer: .space 4
	
	array: .space 25 # przestrzeń do przechowywania 25 (5x5) pixeli 
	
.text
	.globl main
	
	# $t0 --- deskryptor pliku wejściowego
	# $s0 --- rozmiar pliku
	# $s1 --- szerokość
	# $s2 --- wysokość
	# $t1 --- adres zaalokowanej pamięci
	# $t2 --- wskazuje przeglądany piksel
	
main:
	# wyświetlenie komunikatu na początek
	li $v0, 4
	la $a0, welcomeMessage
	syscall

readFileInformation:
	 # otworzenie pliku
	 li $v0, 13
	 la $a0, inputFileName
	 li $a1, 0
	 li $a2, 0
	 syscall
	 
	 move $t0, $v0 # pobranie deskryptora pliku
	 
	 bltz $t0, cannotOpenFile # skok gdy nie udało się otworzyć pliku
	 
	 # wczytanie 2 bajtów FileType
	 li $v0, 14
	 move $a0, $t0
	 la $a1, buffor
	 li $a2, 2
	 syscall
	 
	 # wczytanie 4 bajtów FileSize
	 li $v0, 14
	 move $a0, $t0
	 la $a1, sizeBuffor
	 li $a2, 4
	 syscall
	 
	 # rozmiar pliku zapisany do $s0
	 lw  $s0, sizeBuffor # !!!!!!!!!!!!!!!potencjalny błąd
	 
	 # wczytanie 4 bajtów Reserver
	 li $v0, 14
	 move $a0, $t0
	 la $a1, reservedBuffor
	 li $a2, 4
	 syscall
	 
	 # wczytanie 4 bajtów offsetu
	 li $v0, 14
	 move $a0, $t0
	 la $a1, offsetBuffor
	 li $a2, 4
	 syscall
	 
	 # wczytanie 4 bajtów header'a
	 li $v0, 14
	 move $a0 $t0
	 la $a1, headerBuffor
	 li $a2, 4
	 syscall
	 
	 # wczytanie 4 bajtów szerokosci
	 li $v0, 14
	 move $a0, $t0
	 la $a1, widthBuffer
	 li $a2, 4
	 syscall
	 
	 lw $s1, widthBuffer # załaduj szerokość do $s1
	 
	  # wczytanie 4 bajtów wysokosci
	 li $v0, 14
	 move $a0, $t0
	 la $a1, heightBuffer
	 li $a2, 4
	 syscall
	 
	 lw $s2, heightBuffer # załaduj wysokość do $s2
	 
	 # zamyknięcie pliku
	 li $v0, 16
	 move $a0, $t0
	 syscall
	 
copyBitmap:
	 # zaalokowanie pamięci na bitmapę
	 li $v0, 9
	 move $a0, $s0
	 syscall
	 
	 move $t1, $v0 # umieszczenie adresu do zaalokowanej pamięci w $t1
	 #################tutaj moze cos powinno byc########################################
	 
	 # otworzenie pliku
	 li $v0, 13
	 la $a0, inputFileName
	 li $a1, 0
	 li $a2, 0
	 syscall
	 
	 move $t0, $v0 # pobranie deskryptora pliku
	 
	 bltz $t0, cannotOpenFile # sprawdzenie poprawności otwarcia pliku
	 
	 # wczytanie pliku do zaalokowanej pamięci
	 li $v0, 14
	 move $a0, $t0
	 la $a1, ($t1)
	 la $a2, ($s0)
	 syscall
	 
	 #zamknięcie pliku
	 li $v0, 16
	 move $a0, $t0
	 syscall
	 
	 # ustawienie t2 tak aby wskazywało pierwszy pixel
	 lw $t2, offsetBuffor
	 addu $t2, $t2, $t1
	 
	 
	 # $t6 --- wiersz aktualnie rozważanego pixela
	 # $t7 --- kolumna aktualnie rozważanego pixela
	 # $t8 --- licznik iteracji w jednym wierszu
	 # $t9 --- licznik iteracji wierszy
	 # $t4 --- numer wiersza (w iteracji)
	 # $t5 --- numer kolumny (w iteracji)
	 # $s4 --- padding
	 # $t3 --- liczba pixeli włożonych do tablicy
	 # $s7 --- początek tablicy zawierającej zmodyfikowane pixele
	 
	 
	 #alokacja miejsce na tablicę przechowującą zmodyfikowane pixele
	 li $v0, 9
	 move $a0, $s0
	 syscall
	 move $s7, $v0
	 
	 addiu $t6, $zero, 0
	 addiu $t7, $zero, 0
	 addiu $t8, $zero, 0
	 addiu $t9, $zero, 0
	 
	 andi $s4, $s1, 3 # reszta z dzielenia szerokości przez 4
	 
	 beq $s4, 0, analizePixel
	 
	 addi $t4, $zero, 4
	 sub $s4, $t4, $s4
	 
	 
	 
	 
analizePixel:
	addi $t3, $zero, 0 # wyzerowanie licznika elementów w tablicy
	
	addi $t4, $t6, -2
	addi $t5, $t7, -2
	addi $t8, $zero, 0
	addi $t9, $zero, 0
	
	# ustawienie $t0 aby wskazywało pierwszy pixel z siatki 5x5
	move $t0, $t2
	sub $t0, $t0, $s1 # 2 wiersze do góry
	sub $t0, $t0, $s1
	sub $t0, $t0, $s4 # i padding
	sub $t0, $t0, $s4
	subi $t0, $t0, 2
	
loopNr1:
	#lbu $t9, ($t2)
	
	#li $v0, 1
	#move $a0, $t4
	#syscall
	#li $v0, 4
	#la $a0, space
	#syscall
	#li $v0, 1
	#move $a0, $t5
	#syscall
	#li $v0, 4
	#la $a0, enter
	#syscall
	
	#sprawdzenie czy pixel który chcemy dodać do tablicy mieści się w bitmapie
	blt $t4, 0, nextPixel
	blt $t5, 0, nextPixel
	bge $t4, $s2, nextPixel
	bge $t5, $s1, nextPixel
	
	# załadowanie bajtu do tablicy
	#addi $s7, 
	#addu $t2, $t2, $t1
	lbu $s5, ($t0) # wyciągnięcie wartości spod pixela wskazywanego przez $t0
	sb $s5, array($t3) # dodanie elementu do tablicy
	addi $t3, $t3, 1 # zwiększenie licznika elementów w tablicy
	
	#li $v0, 1
	#move $a0, $s5
	#syscall
	
	j nextPixel
	
sort:	#na razie tylko wypisuje to co jest w tablicy
	addi $s6, $zero, 0
unsortedPrint:
	#lbu $s5, array($s6)
	#addi $s6, $s6, 1 
	
	#li $v0, 1
	#move $a0, $s5
	#syscall
	
	#li $v0, 4
	#la $a0, space
	#syscall
	
	#bne $s6, $t3, unsortedPrint
	#li $v0, 4
	#la $a0, enter
	#syscall


	# $s6 - licznik zewnętrznej pętli
	# $s5 - licznik wewnętrznej pętli
	move $s6, $t3
	
sortLoop1: 
	addi $s5, $zero, 1
sortLoop2:
	# załadowanie do $s0 i $s3 elementów tablicy o indeksach $s5 i $s5+1
	addi $s5, $s5, -1
	lbu $s0, array($s5)
	addi $s5, $s5, 1
	lbu $s3, array($s5)
	addi $s5, $s5, -1
	
	ble $s0, $s3, afterSwap
	# swap - załadowanie do tablicy $s0 i $s3 w odwrotnej kolejności
	#li $v0, 1
	#move $a0, $s0
	#syscall
	#li $v0, 4
	#la $a0, space
	#syscall
	#li $v0, 1
	#move $a0, $s3
	#syscall
	#li $v0, 4
	#la $a0, enter
	#syscall
	
	sb $s3, array($s5)
	addi $s5, $s5, 1
	sb $s0, array($s5)
	addi $s5, $s5, -1

afterSwap:
	addi $s5, $s5, 2
	blt $s5, $s6, sortLoop2 # while $s5 < $6 - 1
# sortLoop2 END	
	addi $s6, $s6, -1
	bgt $s6, 0, sortLoop1 # while $s6 > 1
# sortLoop1 END	
	addi $s6, $zero, 0
sortedPrint:
	#lbu $s5, array($s6)
	#addi $s6, $s6, 1 
	
	#li $v0, 1
	#move $a0, $s5
	#syscall
	
	#li $v0, 4
	#la $a0, space
	#syscall
	
	#bne $s6, $t3, sortedPrint
	
	
	
endSort:
	#li $v0, 4
	#la $a0, enter
	#syscall
	
	#li $v0, 1
	#move $a0, $t6
	#syscall
	
	#li $v0, 4
	#la $a0, space
	#syscall
	
	#li $v0, 1
	#move $a0, $t7
	#syscall
	
	#li $v0, 4
	#la $a0, enter
	#syscall
	
	
#########	########## END SORT #############	##########
	
	# $s5 - numer analizowanego pixela i tym samym indeks pod który wrzucamy pixel w zmodyfikowanej tablicy
	move $s5, $s1
	add $s5, $s5, $s4 # szerokość wiersza z paddingiem
	mul $s5, $s5, $t6 # pomnożenie razy numer wiersza
	add $s5, $s5, $t7 # dodanie numeru kolumny
	
	add $s5, $s5, $s7 # teraz $s5 wskazuje miejsce gdzie należy wstawić wartość pixela
	
	move $s0, $t3
	
	sra $s0, $s0, 1
	
	lbu $s0, array($s0) # wstawiamy do $s0 medianę
	sb $s0, ($s5) # i ładujemy ją do tablicy	
	
	addiu $t2, $t2, 1 # przesuń wskaznik pixela
	addiu $t7, $t7, 1 # zwiększ numer kolumny
	bne $t7, $s1, analizePixel # jeśli nie doszliśmy do końca wiersza to kontynuuj
	
	# doszliśmy do końca wiersza
	addiu $t7, $zero, 0 # ustawiamy numer kolumny na 0
	addiu $t6, $t6, 1 # zwiększamy numer wiersza
	add $t2, $t2, $s4 # przesunięcie uwzględniające padding
	bne $t6, $s2, analizePixel # jeśli nie przeszliśmy ostatniego wiersza to kontynuujemy
	
	j print
	j saveFile
	
nextPixel:
	# przejście do następnego piksela do dodania
	addi $t8, $t8, 1
	addi $t5, $t5, 1
	addi $t0, $t0, 1
	bne $t8, 5, loopNr1
	addi $t8, $zero, 0
	addi $t5, $t7, -2
	addi $t4, $t4, 1
	addi $t9, $t9, 1
	
	subi $t0, $t0, 5
	add $t0, $t0, $s1
	add $t0, $t0, $s4
	
	bne $t9, 5, loopNr1
	j sort
		 
	#li $v0, 1
	#move $a0, $s1
	#syscall
	
	#li $v0, 4
	#la $a0, space
	#syscall
	
	#li $v0, 1
	#move $a0, $s2
	#syscall
	
	 
print:
	#lw $t2, offsetBuffor
	#addu $t2, $t2, $t1
	move $t2, $s7
	addi $t7, $zero, 0
loop1:
	addi $t8, $zero, 0
loop2:
	lbu $t9, ($t2)
	addiu $t2, $t2, 1
	
	li $v0, 1
	move $a0, $t9
	syscall
	
	li $v0, 4
	la $a0, space
	syscall
	
	addi $t8, $t8, 1
	
	bne $t8,16, loop2
	
	li $v0, 4
	la $a0, enter
	syscall
	
	addi $t7, $t7, 1
	
	bne $t7,16, loop1
	 
swapPixels:
	lw $t2, offsetBuffor
	addu $t2, $t2, $t1 # $t2 wskazuje pierwsze miejsce do wstawienia pixela
	move $s0, $s7 # $s0 wskazuje pierwszy pixel do wstawienia
	
	move $s6, $s1
	add $s6, $s6, $s4 # $s6 szerokość wiersza wraz z paddingiem
	
	addi $t7, $zero, 0
swapLoop1:
	addi $t8, $zero, 0
swapLoop2:
	lbu $t9, ($s0)
	addi $s0, $s0, 1
	
	sb $t9, ($t2)
	addi $t2, $t2, 1
	
	addi $t8, $t8, 1
	
	bne $t8,$s6, swapLoop2
	
	li $v0, 4
	la $a0, enter
	syscall
	
	addi $t7, $t7, 1
	
	bne $t7,$s2, swapLoop1 
	 
	 
	 
	 
	 
	 
saveFile: ################## nie zapisuje #######################################
	# otwórz plik
	li $v0, 13
	la $a0, inputFileName
	li $a1, 1 # flaga zapisywania
	li $a2, 0
	syscall
	
	move $t0, $v0 # pobranie deskryptora pliku

	bltz $t0, cannotOpenFile
	
	lw $s0, sizeBuffor # umieszczenie rozmiaru w $s0
	
	# zapisanie pliku
	li $v0, 15
	move $a0, $t0
	la $a1, ($t1) # początek zaalokowanej pamięci
	la $a2, ($s0) # rozmiar pliku
	syscall
	
	#zamknięcie pliku
	li $v0, 16
	move $a0, $t0
	syscall
	
	li $v0, 1
	move $a0, $s0
	syscall
	
	j exit
	 
cannotOpenFile:
	li $v0, 4
	la $a0, errorMessage
	syscall
	
	 
	 
exit:
	li $v0, 4
	la $a0, endMessage
	syscall
	# zakończenie działania programu 
	li $v0, 10
	syscall
	
	
