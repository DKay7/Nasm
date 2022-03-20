extern void Printf (const char* format, ...);


int main()
{   
    Printf ("I %s %x %d%%%c%b\n", "love", 3802, 100, 33, 15);
    return 0;
}