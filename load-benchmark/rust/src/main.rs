fn sieve_of_eratosthenes(n: usize) -> Vec<usize> {
    let mut is_prime = vec![true; n + 1];
    is_prime[0] = false;
    is_prime[1] = false;

    for i in 2..=((n as f64).sqrt() as usize) {
        if is_prime[i] {
            for j in (i * i..=n).step_by(i) {
                is_prime[j] = false;
            }
        }
    }

    let mut primes = Vec::new();
    for i in 2..=n {
        if is_prime[i] {
            primes.push(i);
        }
    }
    primes
}

fn main() {
    let n = 1_000_000;
    let start = std::time::Instant::now();
    let primes = sieve_of_eratosthenes(n);
    let duration = start.elapsed();
    println!(
        "Found {} primes up to {} in {:?}",
        primes.len(),
        n,
        duration
    );
}
