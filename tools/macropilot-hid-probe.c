// MacroPilot's deliberately small, macOS-only HID diagnostic.
//
// It never changes a binding. With --version-query it sends the vendor
// configurator's zeroed version request through report IDs 0, 2, and 3.
// That is useful for identifying the write channel before a mapper is built.

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static long number_property(IOHIDDeviceRef device, CFStringRef key) {
  CFTypeRef value = IOHIDDeviceGetProperty(device, key);
  long number = -1;
  if (value && CFGetTypeID(value) == CFNumberGetTypeID()) {
    CFNumberGetValue((CFNumberRef)value, kCFNumberLongType, &number);
  }
  return number;
}

static void probe_device(IOHIDDeviceRef device, int send_version_query, int seize) {
  long vendor = number_property(device, CFSTR(kIOHIDVendorIDKey));
  long product = number_property(device, CFSTR(kIOHIDProductIDKey));
  long usage_page = number_property(device, CFSTR(kIOHIDPrimaryUsagePageKey));
  long usage = number_property(device, CFSTR(kIOHIDPrimaryUsageKey));

  if (vendor != 0x1189 || product != 0x8890) return;

  printf("found 1189:8890 — usage page %ld, usage %ld\n", usage_page, usage);
  if (!send_version_query) return;

  IOOptionBits options = seize ? kIOHIDOptionsTypeSeizeDevice : kIOHIDOptionsTypeNone;
  IOReturn opened = IOHIDDeviceOpen(device, options);
  if (opened != kIOReturnSuccess) {
    printf("  cannot open: 0x%08x\n", opened);
    return;
  }

  uint8_t request[64] = {0}; // Vendor app's non-mutating version query payload.
  for (CFIndex report_id = 0; report_id <= 3; report_id++) {
    if (report_id == 1) continue; // The vendor app tries 0, then 2, then 3.
    IOReturn result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput,
                                           report_id, request, sizeof(request));
    printf("  report ID %ld: %s (0x%08x)\n", (long)report_id,
           result == kIOReturnSuccess ? "accepted by macOS" : "rejected",
           result);
  }
  IOHIDDeviceClose(device, options);
}

int main(int argc, char **argv) {
  int send_version_query = argc == 2 && strcmp(argv[1], "--version-query") == 0;
  int seize = argc == 2 && strcmp(argv[1], "--seize-version-query") == 0;
  if (argc > 1 && !send_version_query && !seize) {
    fprintf(stderr, "usage: %s [--version-query | --seize-version-query]\n", argv[0]);
    return 2;
  }

  IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
  if (!manager) return 1;
  IOHIDManagerSetDeviceMatching(manager, NULL);
  IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);

  CFSetRef devices = IOHIDManagerCopyDevices(manager);
  if (!devices) {
    fprintf(stderr, "No HID devices were visible.\n");
    CFRelease(manager);
    return 1;
  }

  CFIndex count = CFSetGetCount(devices);
  IOHIDDeviceRef *items = calloc((size_t)count, sizeof(*items));
  CFSetGetValues(devices, (const void **)items);
  for (CFIndex i = 0; i < count; i++) probe_device(items[i], send_version_query || seize, seize);

  free(items);
  CFRelease(devices);
  CFRelease(manager);
  return 0;
}
