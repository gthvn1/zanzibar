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
}
