"""Arena allocator for zero-copy FIX message parsing.

⚠️ WARNING: This is an UNSAFE module for high-frequency trading.
- Manual memory management required
- No automatic bounds checking
- Arena must outlive all views
"""

from memory import UnsafePointer, memcpy


struct Arena:
    """Pre-allocated memory arena for zero-copy parsing.

    Uses bump-pointer allocation for maximum speed.
    No deallocation - reset entire arena when done.
    """

    var buffer: UnsafePointer[UInt8]
    var capacity: Int
    var offset: Int
    var owns_memory: Bool

    fn __init__(out self, capacity: Int = 1024 * 1024):
        """Create arena with specified capacity (default 1MB).

        Args:
            capacity: Size of arena in bytes.
        """
        self.capacity = capacity
        self.offset = 0
        self.buffer = UnsafePointer[UInt8].alloc(capacity)
        self.owns_memory = True

    fn __init__(
        out self, external_buffer: UnsafePointer[UInt8], capacity: Int
    ):
        """Create arena wrapping external buffer (zero-allocation mode).

        Args:
            external_buffer: Pre-allocated buffer.
            capacity: Size of buffer in bytes.
        """
        self.buffer = external_buffer
        self.capacity = capacity
        self.offset = 0
        self.owns_memory = False

    fn __del__(deinit self):
        """Free arena memory if owned."""
        if self.owns_memory:
            self.buffer.free()

    fn allocate(mut self, size: Int) -> UnsafePointer[UInt8]:
        """Allocate bytes from arena (bump pointer).

        Args:
            size: Number of bytes to allocate.

        Returns:
            Pointer to allocated memory, or null if arena full.
        """
        if self.offset + size > self.capacity:
            # Arena exhausted - return null pointer
            return UnsafePointer[UInt8]()

        var ptr = self.buffer + self.offset
        self.offset += size
        return ptr

    fn write_bytes(
        mut self, data: UnsafePointer[UInt8], size: Int
    ) -> UnsafePointer[UInt8]:
        """Write bytes to arena and return pointer.

        Args:
            data: Source data.
            size: Number of bytes.

        Returns:
            Pointer to copied data in arena.
        """
        var dest = self.allocate(size)
        if dest:
            memcpy(dest, data, size)
        return dest

    fn reset(mut self):
        """Reset arena to empty state (reuse memory)."""
        self.offset = 0

    fn available(self) -> Int:
        """Get remaining capacity in bytes."""
        return self.capacity - self.offset

    fn used(self) -> Int:
        """Get used capacity in bytes."""
        return self.offset

    fn is_full(self) -> Bool:
        """Check if arena is full."""
        return self.offset >= self.capacity
