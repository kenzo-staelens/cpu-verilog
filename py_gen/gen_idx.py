def f(i,a):
    return (((8-i)-a-1)%8)*8+7, ((16-i-a-1)%8)*8

for i in range(8):
    for a in range(8):
        x,y = f(i,a)
        print(f"[{x:2d}:{y:2d}]", end=' ')
    print()