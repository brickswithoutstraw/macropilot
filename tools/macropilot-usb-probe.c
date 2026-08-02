// MacroPilot raw-USB version probe for the six-key/one-knob 1189:8890 pad.
// This talks only to its non-keyboard configuration interface (1 / endpoint 2).
// It does not send any key, layer, LED, or commit command.

#include <libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { vendor_id = 0x1189, product_id = 0x8890, config_interface = 1, out_endpoint = 0x02 };

int main(int argc, char **argv) {
  if (argc != 2 || strcmp(argv[1], "--version-query") != 0) {
    fprintf(stderr, "usage: %s --version-query\n", argv[0]);
    return 2;
  }

  libusb_context *context = NULL;
  libusb_device_handle *handle = NULL;
  if (libusb_init(&context) != 0) return 1;
  handle = libusb_open_device_with_vid_pid(context, vendor_id, product_id);
  if (!handle) {
    fprintf(stderr, "1189:8890 pad not found.\n");
    libusb_exit(context);
    return 1;
  }

  libusb_set_auto_detach_kernel_driver(handle, 1);
  int claimed = libusb_claim_interface(handle, config_interface);
  if (claimed != 0) {
    fprintf(stderr, "Could not claim configuration interface %d: %s\n", config_interface,
            libusb_error_name(claimed));
    libusb_close(handle);
    libusb_exit(context);
    return 1;
  }

  for (unsigned char report_id = 0; report_id <= 3; report_id++) {
    if (report_id == 1) continue; // Matches the vendor app's 0 → 2 → 3 probe order.
    unsigned char request[64] = {0};
    request[0] = report_id;
    int transferred = 0;
    int result = libusb_interrupt_transfer(handle, out_endpoint, request, sizeof(request),
                                           &transferred, 250);
    printf("report ID %u: %s (%d bytes)\n", report_id,
           result == 0 ? "transport accepted" : libusb_error_name(result), transferred);
  }

  libusb_release_interface(handle, config_interface);
  libusb_close(handle);
  libusb_exit(context);
  return 0;
}
