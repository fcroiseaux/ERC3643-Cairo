#[cfg(test)]
mod tests {
    #[test]
    fn test_code_compiles() {
        // This test verifies that our code compiles after making changes
        assert(true, 'Code should compile');
    }
    
    #[test]
    fn test_basic_math() {
        // Simple test to ensure the testing framework works
        assert(2 + 2 == 4, 'Basic math should work');
    }
}