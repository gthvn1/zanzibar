const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "zanzibar",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
    });

    b.installArtifact(exe);

    // Add run cmd
    const run_cmd = b.addRunArtifact(exe);
    // And add its corresponding step
    const run_step = b.step("run", "Run zanzibar repl");
    run_step.dependOn(&run_cmd.step);

    // Create a step for running unit tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
