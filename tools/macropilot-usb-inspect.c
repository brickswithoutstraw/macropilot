// Read-only raw USB descriptor inspector for MacroPilot adapters.
// This does not open, claim, detach, or write to the macropad.

#include <libusb.h>
#include <stdio.h>

int main(void) {
  libusb_context *context = NULL;
  libusb_device **devices = NULL;
  if (libusb_init(&context) != 0) return 1;

  ssize_t count = libusb_get_device_list(context, &devices);
  if (count < 0) {
    libusb_exit(context);
    return 1;
  }

  int found = 0;
  for (ssize_t i = 0; i < count; i++) {
    struct libusb_device_descriptor descriptor;
    if (libusb_get_device_descriptor(devices[i], &descriptor) != 0 ||
        descriptor.idVendor != 0x1189 || descriptor.idProduct != 0x8890) continue;
    found = 1;
    printf("1189:8890 at bus %u, address %u\n", libusb_get_bus_number(devices[i]),
           libusb_get_device_address(devices[i]));

    struct libusb_config_descriptor *config = NULL;
    if (libusb_get_config_descriptor(devices[i], 0, &config) != 0) continue;
    for (uint8_t interface_index = 0; interface_index < config->bNumInterfaces; interface_index++) {
      const struct libusb_interface *interface = &config->interface[interface_index];
      for (int alt = 0; alt < interface->num_altsetting; alt++) {
        const struct libusb_interface_descriptor *setting = &interface->altsetting[alt];
        printf("  interface %u alt %u: class %02x/%02x/%02x\n",
               setting->bInterfaceNumber, setting->bAlternateSetting,
               setting->bInterfaceClass, setting->bInterfaceSubClass,
               setting->bInterfaceProtocol);
        for (uint8_t endpoint_index = 0; endpoint_index < setting->bNumEndpoints; endpoint_index++) {
          const struct libusb_endpoint_descriptor *endpoint = &setting->endpoint[endpoint_index];
          const char *direction = (endpoint->bEndpointAddress & LIBUSB_ENDPOINT_IN) ? "IN" : "OUT";
          printf("    %s endpoint 0x%02x, attributes 0x%02x, packet %u\n", direction,
                 endpoint->bEndpointAddress, endpoint->bmAttributes,
                 endpoint->wMaxPacketSize);
        }
      }
    }
    libusb_device_handle *handle = NULL;
    if (libusb_open(devices[i], &handle) == 0) {
      unsigned char report_descriptor[512] = {0};
      for (uint16_t interface_number = 0; interface_number < config->bNumInterfaces; interface_number++) {
        int length = libusb_control_transfer(
            handle, LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_STANDARD | LIBUSB_RECIPIENT_INTERFACE,
            LIBUSB_REQUEST_GET_DESCRIPTOR, (LIBUSB_DT_REPORT << 8), interface_number,
            report_descriptor, sizeof(report_descriptor), 250);
        if (length > 0) {
          printf("  interface %u HID report descriptor (%d bytes):", interface_number, length);
          for (int byte = 0; byte < length; byte++) printf(" %02x", report_descriptor[byte]);
          printf("\n");
        } else {
          printf("  interface %u HID report descriptor: %s\n", interface_number,
                 libusb_error_name(length));
        }
      }
      libusb_close(handle);
    }
    libusb_free_config_descriptor(config);
  }

  if (!found) printf("No 1189:8890 device found.\n");
  libusb_free_device_list(devices, 1);
  libusb_exit(context);
  return found ? 0 : 2;
}
