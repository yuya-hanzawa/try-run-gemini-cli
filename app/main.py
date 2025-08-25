import pandas as pd

def add(a, b):
    try:
        a = int(a)
        b = int(b)
        sum = a + b
    except Exception:
        pass

    return sum

def main():
    result = add(2, 5)

if __name__=="__main__":
    main()
