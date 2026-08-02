// Minimal raw-USB mapper for the SIKAI-style 1189:8890 firmware.
// It supports a visible one-key smoke test and MacroPilot's neutral F-key
// layout. Its compact report layout is independently documented for this
// VID/PID family and matches the bundled configurator.

#include <libusb.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

enum { vendor_id = 0x1189, product_id = 0x8890, config_interface = 1, out_endpoint = 0x02 };

static void build_simple_key_part(unsigned char packet[65], unsigned char key_id,
                                  unsigned char layer, unsigned char part,
                                  unsigned char modifier, unsigned char hid_code) {
  memset(packet, 0, 65);
  // Report ID 3 + compact configuration payload. One simple keyboard key is
  // transmitted as an initial modifier record followed by the actual key.
  packet[0] = 0x03;
  packet[1] = key_id;
  packet[2] = (layer << 4) | 0x01; // layer/type: keyboard
  packet[3] = 0x01; // one keyboard key in the group
  packet[4] = part; // 0: modifier setup, 1: actual key
  packet[5] = modifier;
  packet[6] = hid_code;
}

static void build_commit(unsigned char packet[65]) {
  memset(packet, 0, 65);
  packet[0] = 0x03;
  packet[1] = 0xaa;
  packet[2] = 0xaa;
}

static void print_packet(const char *label, const unsigned char packet[65]) {
  printf("%s:", label);
  for (int i = 0; i < 16; i++) printf(" %02x", packet[i]);
  printf(" …\n");
}

static int send_packet(libusb_device_handle *handle, const unsigned char packet[65]) {
  int transferred = 0;
  int result = libusb_interrupt_transfer(handle, out_endpoint, (unsigned char *)packet,
                                         65, &transferred, 250);
  if (result != 0 || transferred != 65) {
    fprintf(stderr, "USB write failed: %s (%d bytes)\n", libusb_error_name(result), transferred);
    return 1;
  }
  return 0;
}

struct binding { unsigned char key_id; unsigned char hid_code; const char *label; };

static const struct binding macropilot_layout[] = {
  // Physical layout: knob above the left column; key IDs count from bottom-left.
  { 4, 0x68, "top-left → F13" },
  { 5, 0x69, "top-middle → F14" },
  { 6, 0x6a, "top-right → F15" },
  { 1, 0x6b, "bottom-left → F16" },
  { 2, 0x6c, "bottom-middle → F17" },
  { 3, 0x6d, "bottom-right → F18" },
  {13, 0x6e, "knob counterclockwise → F19" },
  {14, 0x70, "knob press → F21" },
  {15, 0x6f, "knob clockwise → F20" },
};

static void print_binding(const struct binding *binding) {
  unsigned char first[65], second[65];
  build_simple_key_part(first, binding->key_id, 1, 0, 0, 0);
  build_simple_key_part(second, binding->key_id, 1, 1, 0, binding->hid_code);
  print_packet(binding->label, first);
  print_packet("  key payload", second);
}

static int send_binding(libusb_device_handle *handle, const struct binding *binding) {
  unsigned char first[65], second[65];
  build_simple_key_part(first, binding->key_id, 1, 0, 0, 0);
  build_simple_key_part(second, binding->key_id, 1, 1, 0, binding->hid_code);
  if (send_packet(handle, first)) return 1;
  usleep(20000);
  return send_packet(handle, second);
}

int main(int argc, char **argv) {
  int layout = argc == 2 && (strcmp(argv[1], "--preview-macropilot-layout") == 0 ||
                             strcmp(argv[1], "--apply-macropilot-layout") == 0);
  int key_a = argc == 2 && (strcmp(argv[1], "--preview-key1-a") == 0 ||
                            strcmp(argv[1], "--apply-key1-a") == 0);
  int apply = argc == 2 && (strcmp(argv[1], "--apply-key1-f13") == 0 ||
                             strcmp(argv[1], "--apply-key1-a") == 0);
  int preview = argc == 2 && (strcmp(argv[1], "--preview-key1-f13") == 0 ||
                               strcmp(argv[1], "--preview-key1-a") == 0);
  if (!apply && !preview && !layout) {
    fprintf(stderr, "usage: %s --preview-key1-a | --apply-key1-a | --preview-key1-f13 | --apply-key1-f13 | --preview-macropilot-layout | --apply-macropilot-layout\n", argv[0]);
    return 2;
  }

  int apply_layout = argc == 2 && strcmp(argv[1], "--apply-macropilot-layout") == 0;
  if (layout) {
    for (size_t i = 0; i < sizeof(macropilot_layout) / sizeof(macropilot_layout[0]); i++) {
      print_binding(&macropilot_layout[i]);
    }
    unsigned char layout_commit[65];
    build_commit(layout_commit);
    print_packet("commit", layout_commit);
    if (!apply_layout) return 0;

    libusb_context *layout_context = NULL;
    if (libusb_init(&layout_context) != 0) return 1;
    libusb_device_handle *layout_handle = libusb_open_device_with_vid_pid(layout_context, vendor_id, product_id);
    if (!layout_handle) { fprintf(stderr, "1189:8890 pad not found.\n"); libusb_exit(layout_context); return 1; }
    libusb_set_auto_detach_kernel_driver(layout_handle, 1);
    int layout_claimed = libusb_claim_interface(layout_handle, config_interface);
    if (layout_claimed != 0) {
      fprintf(stderr, "Could not claim configuration interface: %s\n", libusb_error_name(layout_claimed));
      libusb_close(layout_handle); libusb_exit(layout_context); return 1;
    }
    int layout_failed = 0;
    for (size_t i = 0; i < sizeof(macropilot_layout) / sizeof(macropilot_layout[0]); i++) {
      if (send_binding(layout_handle, &macropilot_layout[i])) { layout_failed = 1; break; }
      usleep(20000);
    }
    if (!layout_failed) layout_failed = send_packet(layout_handle, layout_commit);
    libusb_release_interface(layout_handle, config_interface);
    libusb_close(layout_handle);
    libusb_exit(layout_context);
    return layout_failed;
  }

  unsigned char first[65], second[65], commit[65];
  unsigned char hid_code = key_a ? 0x04 : 0x68; // HID A or F13
  build_simple_key_part(first, 1, 1, 0, 0, 0);
  build_simple_key_part(second, 1, 1, 1, 0, hid_code);
  build_commit(commit);
  print_packet("key 1: modifier setup", first);
  print_packet(key_a ? "key 1 -> A, layer 1" : "key 1 -> F13, layer 1", second);
  print_packet("commit", commit);
  if (!apply) return 0;

  libusb_context *context = NULL;
  if (libusb_init(&context) != 0) return 1;
  libusb_device_handle *handle = libusb_open_device_with_vid_pid(context, vendor_id, product_id);
  if (!handle) { fprintf(stderr, "1189:8890 pad not found.\n"); libusb_exit(context); return 1; }
  libusb_set_auto_detach_kernel_driver(handle, 1);
  int claimed = libusb_claim_interface(handle, config_interface);
  if (claimed != 0) {
    fprintf(stderr, "Could not claim configuration interface: %s\n", libusb_error_name(claimed));
    libusb_close(handle); libusb_exit(context); return 1;
  }
  int failed = send_packet(handle, first);
  if (!failed) usleep(20000);
  if (!failed) failed = send_packet(handle, second);
  if (!failed) usleep(100000);
  if (!failed) failed = send_packet(handle, commit);
  libusb_release_interface(handle, config_interface);
  libusb_close(handle);
  libusb_exit(context);
  return failed;
}
