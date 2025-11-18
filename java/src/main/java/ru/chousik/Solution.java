package ru.chousik;

public class Solution {
    public static long sumDiagonals(int n) {
        if (n == 1) return 1;
        long sum = 1;
        int layers = (n - 1) / 2;
        for (int k = 1; k <= layers; k++) {
            sum += 16L * k * k + 4L * k + 4;
        }
        return sum;
    }

    public static long largestPrimeFactor(long n) {
        long factor = 2;
        while (factor * factor <= n) {
            if (n % factor == 0) {
                n /= factor;
            } else {
                factor++;
            }
        }
        return n;
    }
}
