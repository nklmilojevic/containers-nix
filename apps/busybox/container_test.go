package main

import (
	"context"
	"testing"

	"github.com/nklmilojevic/containers-nix/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/nklmilojevic/busybox:rolling")
	testhelpers.TestCommandSucceeds(t, ctx, image, nil, "/bin/busybox", "--list")
}
