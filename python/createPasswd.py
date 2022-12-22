import string,random
print(''.join(random.choice(string.ascii_letters + string.digits + string.punctuation) for _ in range(12)))