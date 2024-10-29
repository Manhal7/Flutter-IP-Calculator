// Main application widget that sets up the theme and initial screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';

// Enhanced NetworkInfo class to support both IPv4 and IPv6
class NetworkInfo {
  final String address; // IP address (IPv4 or IPv6)
  final String netmask; // Subnet mask
  final String network; // Network address
  final String binary; // Binary representation
  final int cidr; // CIDR notation value
  final bool isIPv6; // Flag to indicate IP version
  final Map<String, dynamic> details; // Additional network information

  // IPv4-specific fields
  final String? wildcard; // Wildcard mask (IPv4 only)
  final String? broadcast; // Broadcast address (IPv4 only)
  final String? hostMin; // First usable host (IPv4 only)
  final String? hostMax; // Last usable host (IPv4 only)
  final int? hostsNet; // Number of usable hosts (IPv4 only)
  final String? networkClass; // Network class A, B, C, etc. (IPv4 only)

  // IPv6-specific fields
  final String? expandedAddress; // Fully expanded IPv6 address
  final String? compressedAddress; // Compressed IPv6 address
  final String? interfaceId; // Interface identifier
  final String? globalId; // Global routing prefix

  NetworkInfo({
    required this.address,
    required this.netmask,
    required this.network,
    required this.binary,
    required this.cidr,
    required this.isIPv6,
    required this.details,
    this.wildcard,
    this.broadcast,
    this.hostMin,
    this.hostMax,
    this.hostsNet,
    this.networkClass,
    this.expandedAddress,
    this.compressedAddress,
    this.interfaceId,
    this.globalId,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'netmask': netmask,
        'network': network,
        'binary': binary,
        'cidr': cidr,
        'isIPv6': isIPv6,
        'details': details,
        if (!isIPv6) ...{
          'wildcard': wildcard,
          'broadcast': broadcast,
          'hostMin': hostMin,
          'hostMax': hostMax,
          'hostsNet': hostsNet,
          'networkClass': networkClass,
        },
        if (isIPv6) ...{
          'expandedAddress': expandedAddress,
          'compressedAddress': compressedAddress,
          'interfaceId': interfaceId,
          'globalId': globalId,
        },
      };
}

class IPCalculatorScreen extends StatefulWidget {
  const IPCalculatorScreen({super.key});

  @override
  State<IPCalculatorScreen> createState() => _IPCalculatorScreenState();
}

class _IPCalculatorScreenState extends State<IPCalculatorScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _maskController = TextEditingController();
  String _result = '';
  String _errorMessage = '';
  bool _hasError = false;
  bool _isIPv6 = false;
  NetworkInfo? _networkInfo;

  @override
  void dispose() {
    _ipController.dispose();
    _maskController.dispose();
    super.dispose();
  }

  // Detect IP version from input
  bool _detectIPv6(String ip) {
    return ip.contains(':');
  }

  // Validate IPv6 address format
  bool _isValidIPv6(String ip) {
    try {
      List<String> parts = ip.split(':');
      if (parts.length > 8) return false;

      // Handle compressed notation (::)
      if (ip.contains('::')) {
        if (ip.indexOf('::') != ip.lastIndexOf('::')) return false;
        int missingSegments = 8 - parts.where((p) => p.isNotEmpty).length;
        if (missingSegments < 0) return false;
      }

      // Validate each hexadecimal part
      for (String part in parts) {
        if (part.isEmpty) continue;
        if (part.length > 4) return false;
        int? value = int.tryParse(part, radix: 16);
        if (value == null || value < 0 || value > 0xFFFF) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Expand shortened IPv6 address to full form
  String _expandIPv6(String ip) {
    if (!ip.contains('::')) {
      return ip.split(':').map((part) => part.padLeft(4, '0')).join(':');
    }

    List<String> parts = ip.split('::');
    List<String> start = parts[0].isEmpty ? [] : parts[0].split(':');
    List<String> end =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1].split(':') : [];

    int missing = 8 - (start.length + end.length);
    List<String> middle = List.filled(missing, '0000');

    return [...start, ...middle, ...end]
        .map((part) => part.padLeft(4, '0'))
        .join(':');
  }

  // Convert IPv6 address to compressed form
  String _compressIPv6(String expandedIP) {
    List<String> parts = expandedIP.split(':');
    List<List<String>> zeroGroups = [];
    List<String> currentGroup = [];

    // Find zero groups
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == '0000') {
        currentGroup.add(parts[i]);
      } else if (currentGroup.isNotEmpty) {
        zeroGroups.add(List.from(currentGroup));
        currentGroup = [];
      }
    }
    if (currentGroup.isNotEmpty) {
      zeroGroups.add(currentGroup);
    }

    // Find longest zero sequence
    List<String>? longestGroup;
    int maxLength = 0;
    for (var group in zeroGroups) {
      if (group.length > maxLength) {
        maxLength = group.length;
        longestGroup = group;
      }
    }

    // Compress the address
    if (longestGroup != null && longestGroup.length > 1) {
      int startIndex = parts.indexOf(longestGroup.first);
      parts.replaceRange(startIndex, startIndex + longestGroup.length, ['']);
    }

    return parts
        .map((part) => part.isEmpty ? part : part.replaceAll(RegExp('^0+'), ''))
        .join(':')
        .replaceAll(RegExp(':+'), '::');
  }

  // Calculate IPv6 network information
  void _calculateIPv6Network(String ip, int prefixLength) {
    // Expand the address to full form
    String expandedIP = _expandIPv6(ip);

    // Convert to binary
    String binary = expandedIP
        .split(':')
        .map((part) =>
            int.parse(part, radix: 16).toRadixString(2).padLeft(16, '0'))
        .join('');

    // Calculate network prefix
    String networkBinary = binary.substring(0, prefixLength).padRight(128, '0');
    String networkHex = '';
    for (int i = 0; i < 8; i++) {
      String chunk = networkBinary.substring(i * 16, (i + 1) * 16);
      networkHex +=
          int.parse(chunk, radix: 2).toRadixString(16).padLeft(4, '0');
      if (i < 7) networkHex += ':';
    }

    // Create netmask
    String netmaskBinary = '1' * prefixLength + '0' * (128 - prefixLength);
    String netmaskHex = '';
    for (int i = 0; i < 8; i++) {
      String chunk = netmaskBinary.substring(i * 16, (i + 1) * 16);
      netmaskHex +=
          int.parse(chunk, radix: 2).toRadixString(16).padLeft(4, '0');
      if (i < 7) netmaskHex += ':';
    }

    // Extract interface ID and global routing prefix
    String interfaceId = expandedIP.split(':').sublist(4).join(':');
    String globalId = expandedIP.split(':').sublist(0, 4).join(':');

    // Create NetworkInfo object
    _networkInfo = NetworkInfo(
      address: ip,
      netmask: netmaskHex,
      network: networkHex,
      binary: binary,
      cidr: prefixLength,
      isIPv6: true,
      expandedAddress: expandedIP,
      compressedAddress: _compressIPv6(expandedIP),
      interfaceId: interfaceId,
      globalId: globalId,
      details: {
        'Scope': _getIPv6Scope(expandedIP),
        'Type': _getIPv6Type(expandedIP),
        'Interface ID': interfaceId,
        'Global Routing Prefix': globalId,
        'Total Addresses': '2^${128 - prefixLength}',
      },
    );

    // Format results for display
    _result = '''
IPv6 Address: $ip
Expanded:     ${_networkInfo!.expandedAddress}
Compressed:   ${_networkInfo!.compressedAddress}
Prefix:       /$prefixLength

Network Information:
------------------
Network:      ${_networkInfo!.network}/${_networkInfo!.cidr}
Netmask:      ${_networkInfo!.netmask}
Scope:        ${_networkInfo!.details['Scope']}
Type:         ${_networkInfo!.details['Type']}

Address Components:
----------------
Global ID:    ${_networkInfo!.globalId}
Interface ID: ${_networkInfo!.interfaceId}

Additional Details:
----------------
Total Addresses: ${_networkInfo!.details['Total Addresses']}
''';
  }

  // Determine IPv6 address scope
  String _getIPv6Scope(String ip) {
    if (ip.toLowerCase().startsWith('fe80:')) return 'Link-Local';
    if (ip.toLowerCase().startsWith('fec0:')) return 'Site-Local';
    if (ip.toLowerCase().startsWith('fc00:') ||
        ip.toLowerCase().startsWith('fd00:')) return 'Unique Local';
    if (ip.toLowerCase().startsWith('ff00:')) return 'Multicast';
    return 'Global';
  }

  // Determine IPv6 address type
  String _getIPv6Type(String ip) {
    if (ip.toLowerCase().startsWith('ff00:')) return 'Multicast';
    if (ip.toLowerCase().startsWith('fe80:')) return 'Link-Local Unicast';
    if (ip.toLowerCase().startsWith('fc00:') ||
        ip.toLowerCase().startsWith('fd00:')) return 'Unique Local Unicast';
    return 'Global Unicast';
  }

  // Main calculation function
  void _calculateNetwork() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _networkInfo = null;

      if (_ipController.text.isEmpty || _maskController.text.isEmpty) {
        _hasError = true;
        _errorMessage = 'Please enter both IP address and prefix length';
        return;
      }

      _isIPv6 = _detectIPv6(_ipController.text);

      // Parse and validate prefix length
      int prefixLength;
      try {
        prefixLength = int.parse(_maskController.text);
        if (_isIPv6 && (prefixLength < 0 || prefixLength > 128)) {
          throw const FormatException();
        } else if (!_isIPv6 && (prefixLength < 0 || prefixLength > 32)) {
          throw const FormatException();
        }
      } catch (e) {
        _hasError = true;
        _errorMessage = _isIPv6
            ? 'Invalid prefix length (must be between 0 and 128)'
            : 'Invalid prefix length (must be between 0 and 32)';
        return;
      }

      if (_isIPv6) {
        // Validate IPv6 address
        if (!_isValidIPv6(_ipController.text)) {
          _hasError = true;
          _errorMessage = 'Invalid IPv6 address';
          return;
        }
        _calculateIPv6Network(_ipController.text, prefixLength);
      } else {
        // IPv4 calculation
        try {
          // Split and validate IPv4 address
          List<String> parts = _ipController.text.split('.');
          if (parts.length != 4) {
            throw const FormatException('Invalid IPv4 address format');
          }

          List<int> ipOctets = parts.map((part) {
            int value = int.parse(part);
            if (value < 0 || value > 255) {
              throw const FormatException('Invalid IPv4 octet value');
            }
            return value;
          }).toList();

          _calculateIPv4Network(ipOctets, prefixLength);
        } catch (e) {
          _hasError = true;
          _errorMessage = 'Invalid IPv4 address';
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Calculator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address (IPv4 or IPv6)',
                        hintText: 'e.g., 192.168.1.1 or 2001:db8::1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      style: const TextStyle(fontFamily: 'Courier'),
                      onChanged: (value) {
                        setState(() {
                          _isIPv6 = _detectIPv6(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maskController,
                      decoration: InputDecoration(
                        labelText: 'Prefix Length (CIDR)',
                        hintText: _isIPv6 ? 'e.g., 64' : 'e.g., 24',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.filter_list),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _calculateNetwork,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_hasError)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (!_hasError && _result.isNotEmpty)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // IP version indicator
                            Chip(
                              label: Text(_isIPv6 ? 'IPv6' : 'IPv4'),
                              backgroundColor: _isIPv6
                                  ? Colors.blue.shade100
                                  : Colors.green.shade100,
                            ),
                            // Action buttons
                            Row(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy'),
                                  onPressed: () => _copyToClipboard(context),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.download),
                                  label: const Text('Export JSON'),
                                  onPressed: _exportAsJson,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        SelectableText(
                          _result,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // Add a floating action button for quick format conversion
      floatingActionButton: _result.isNotEmpty
          ? FloatingActionButton(
              onPressed: _toggleFormat,
              tooltip: 'Toggle Format',
              child: const Icon(Icons.swap_horiz),
            )
          : null,
    );
  }

  // Toggle between different address formats for IPv6
  void _toggleFormat() {
    if (_isIPv6 && _networkInfo != null) {
      setState(() {
        bool isExpanded = _result.contains(_networkInfo!.expandedAddress!);
        String address = isExpanded
            ? _networkInfo!.compressedAddress!
            : _networkInfo!.expandedAddress!;

        _result = _result.replaceFirst(
          isExpanded
              ? _networkInfo!.expandedAddress!
              : _networkInfo!.compressedAddress!,
          address,
        );
      });
    }
  }

  // Copy results to clipboard
  void _copyToClipboard(BuildContext context) {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Export network information as formatted JSON
  void _exportAsJson() {
    if (_networkInfo != null) {
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(_networkInfo!.toJson());
      Clipboard.setData(ClipboardData(text: jsonString));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON exported to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper function to convert IPv4 integer to string
  String _intToIpv4(int ipInt) {
    return '${(ipInt >> 24) & 255}.'
        '${(ipInt >> 16) & 255}.'
        '${(ipInt >> 8) & 255}.'
        '${ipInt & 255}';
  }

  // Calculate IPv4 network parameters
  void _calculateIPv4Network(List<int> ipOctets, int mask) {
    int fullMask = (0xFFFFFFFF << (32 - mask)) & 0xFFFFFFFF;
    int wildcard = ~fullMask & 0xFFFFFFFF;

    int ipAsInt = (ipOctets[0] << 24) |
        (ipOctets[1] << 16) |
        (ipOctets[2] << 8) |
        ipOctets[3];

    int networkInt = ipAsInt & fullMask;
    int broadcastInt = networkInt | wildcard;
    int firstHostInt = networkInt + (mask == 32 ? 0 : 1);
    int lastHostInt = broadcastInt - (mask == 32 ? 0 : 1);

    // Format addresses
    String ipAddress = _ipController.text;
    String netmaskStr = _intToIpv4(fullMask);
    String wildcardStr = _intToIpv4(wildcard);
    String networkStr = _intToIpv4(networkInt);
    String broadcastStr = _intToIpv4(broadcastInt);
    String firstHostStr = _intToIpv4(firstHostInt);
    String lastHostStr = _intToIpv4(lastHostInt);

    // Calculate usable hosts
    int totalHosts = mask == 32 ? 1 : (pow(2, (32 - mask)).toInt() - 2);

    // Get network classification and details
    String networkClass = _getIPv4NetworkClass(ipOctets);
    Map<String, dynamic> details = _getIPv4AdditionalInfo(ipOctets, mask);

    // Create NetworkInfo object
    _networkInfo = NetworkInfo(
      address: ipAddress,
      netmask: netmaskStr,
      wildcard: wildcardStr,
      network: networkStr,
      broadcast: broadcastStr,
      hostMin: firstHostStr,
      hostMax: lastHostStr,
      hostsNet: totalHosts,
      networkClass: networkClass,
      binary: _ipToBinary(ipAddress),
      cidr: mask,
      isIPv6: false,
      details: details,
    );

    // Format IPv4 results
    _result = '''
Address:   ${_padIPv4(ipAddress)}${_ipToBinary(ipAddress)}
Netmask:   ${_padIPv4(netmaskStr)} = $mask
Wildcard:  ${_padIPv4(wildcardStr)}
=>
Network:   ${_padIPv4('$networkStr/$mask')} ($networkClass)
Broadcast: ${_padIPv4(broadcastStr)}
HostMin:   ${_padIPv4(firstHostStr)}
HostMax:   ${_padIPv4(lastHostStr)}
Hosts/Net: $totalHosts

Network Details:
--------------
Class: $networkClass
Type: ${details['Type']}
RFC1918: ${details['RFC1918 Compliant']}
Default Gateway: ${details['Default Gateway']}
Reverse DNS: ${details['Reverse DNS']}
Subnet Bits: ${details['Subnet Bits']}
Host Bits: ${details['Host Bits']}
''';
  }

  // Helper function to pad IPv4 addresses for alignment
  String _padIPv4(String ip) {
    return ip.padRight(18);
  }

  // Convert IPv4 address to binary notation
  String _ipToBinary(String ip) {
    return ip
        .split('.')
        .map((part) => int.parse(part).toRadixString(2).padLeft(8, '0'))
        .join('.');
  }

  // Determine IPv4 network class
  String _getIPv4NetworkClass(List<int> ipOctets) {
    final firstOctet = ipOctets[0];
    if (firstOctet < 128) return 'Class A';
    if (firstOctet < 192) return 'Class B';
    if (firstOctet < 224) return 'Class C';
    if (firstOctet < 240) return 'Class D (Multicast)';
    return 'Class E (Reserved)';
  }

  // Get additional IPv4 network information
  Map<String, dynamic> _getIPv4AdditionalInfo(List<int> ipOctets, int mask) {
    bool isRFC1918 = (ipOctets[0] == 10) ||
        (ipOctets[0] == 172 && ipOctets[1] >= 16 && ipOctets[1] <= 31) ||
        (ipOctets[0] == 192 && ipOctets[1] == 168);

    String networkType = isRFC1918 ? 'Private' : 'Public';
    if (ipOctets[0] >= 224 && ipOctets[0] <= 239) {
      networkType = 'Multicast';
    }

    return {
      'Type': networkType,
      'RFC1918 Compliant': isRFC1918 ? 'Yes' : 'No',
      'Default Gateway': '${ipOctets[0]}.${ipOctets[1]}.${ipOctets[2]}.1',
      'Reverse DNS': '${ipOctets[3]}.${ipOctets[2]}.${ipOctets[1]}'
          '.${ipOctets[0]}.in-addr.arpa',
      'Subnet Bits': mask,
      'Host Bits': 32 - mask,
    };
  }
}
