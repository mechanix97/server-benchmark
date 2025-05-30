package main

import (
	"fmt"
	"math"
	"time"
)

func sieveOfEratosthenes(n int) []int {
	isPrime := make([]bool, n+1)
	for i := 2; i <= n; i++ {
		isPrime[i] = true
	}

	for i := 2; i <= int(math.Sqrt(float64(n))); i++ {
		if isPrime[i] {
			for j := i * i; j <= n; j += i {
				isPrime[j] = false
			}
		}
	}

	var primes []int
	for i := 2; i <= n; i++ {
		if isPrime[i] {
			primes = append(primes, i)
		}
	}
	return primes
}

func main() {
	n := 1_000_000
	start := time.Now()
	primes := sieveOfEratosthenes(n)
	duration := time.Since(start)
	fmt.Printf("Found %d primes up to %d in %v\n", len(primes), n, duration)
}
