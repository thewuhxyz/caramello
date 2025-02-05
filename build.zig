const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const caramello_mod = b.addModule("caramello", .{ .root_source_file = b.path("src/root.zig") });

    const src = b.addStaticLibrary(.{
        .name = "caramello",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const solana_dep = b.dependency("solana-program-sdk", .{
        .target = target,
        .optimize = optimize,
    });
    const solana_mod = solana_dep.module("solana-program-sdk");
    
    const spl_dep = b.dependency("solana-program-library", .{
        .target = target,
        .optimize = optimize,
    });
    const spl_mod = spl_dep.module("solana-program-library");

    src.root_module.addImport("solana-program-sdk", solana_mod);
    src.root_module.addImport("solana-program-library", spl_mod);
    caramello_mod.addImport("solana-program-sdk", solana_mod);
    caramello_mod.addImport("solana-program-library", spl_mod);

    b.installArtifact(src);
}
