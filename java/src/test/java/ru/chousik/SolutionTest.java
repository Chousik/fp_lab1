package ru.chousik;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class SolutionTest {

    private static final long[][] PRIME_FACTOR_CASES = {
            {4, 2},
            {6, 3},
            {8, 2},
            {9, 3},
            {10, 5},
            {12, 3},
            {14, 7},
            {18, 3},
            {21, 7}
    };

    private static final long[][] SPIRAL_CASES = {
            {1, 1},
            {3, 25},
            {5, 101},
            {7, 261},
            {9, 537},
            {11, 961},
            {101, 692_101}
    };

    @Test
    void largestPrimeFactor_matchesExpectedSamples() {
        for (long[] sample : PRIME_FACTOR_CASES) {
            long input = sample[0];
            long expected = sample[1];
            assertEquals(expected, Solution.largestPrimeFactor(input),
                    () -> "largestPrimeFactor(" + input + ") should be " + expected);
        }
    }

    @Test
    void sumDiagonals_matchesExpectedSamples() {
        for (long[] sample : SPIRAL_CASES) {
            int input = (int) sample[0];
            long expected = sample[1];
            assertEquals(expected, Solution.sumDiagonals(input),
                    () -> "sumDiagonals(" + input + ") should be " + expected);
        }
    }
}
