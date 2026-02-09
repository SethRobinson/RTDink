#pragma once
// Minimal stub for Linux build
inline void InitUnhandledExceptionFilter() {}
class StackWalker {
public:
    StackWalker() {}
    virtual ~StackWalker() {}
};
