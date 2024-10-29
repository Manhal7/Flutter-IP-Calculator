// Main application widget that sets up the theme and initial screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';

class IPCalculatorApp extends StatelessWidget {
  const IPCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Calculator',
      // Configure light theme settings
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Courier',
        brightness: Brightness.light,
      ),
      // Configure dark theme settings
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Courier',
        brightness: Brightness.dark,
      ),
      home: const IPCalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data model class to store network calculation results
class NetworkInfo {
  final String address; // IP address
  final String netmask; // Subnet mask in decimal format
  final String wildcard; // Wildcard mask
  final String network; // Network address
  final String broadcast; // Broadcast address
  final String hostMin; // First usable host address
  final String hostMax; // Last usable host address
  final int hostsNet; // Number of usable hosts
  final String networkClass; // Network class (A, B, C, D, or E)
  final String networkType; // Network type (Private, Public, Multicast)
  final String binary; // Binary representation of IP
  final int cidr; // CIDR notation value
  final Map<String, dynamic> additionalInfo; // Additional network details

  NetworkInfo({
    required this.address,
    required this.netmask,
    required this.wildcard,
    required this.network,
    required this.broadcast,
    required this.hostMin,
    required this.hostMax,
    required this.hostsNet,
    required this.networkClass,
    required this.networkType,
    required this.binary,
    required this.cidr,
    required this.additionalInfo,
  });

  // Convert NetworkInfo object to JSON format
  Map<String, dynamic> toJson() => {
        'address': address,
        'netmask': netmask,
        'wildcard': wildcard,
        'network': network,
        'broadcast': broadcast,
        'hostMin': hostMin,
        'hostMax': hostMax,
        'hostsNet': hostsNet,
        'networkClass': networkClass,
        'networkType': networkType,
        'binary': binary,
        'cidr': cidr,
        'additionalInfo': additionalInfo,
      };
}

// Main screen widget for the IP calculator
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
  NetworkInfo? _networkInfo;

  @override
  void dispose() {
    _ipController.dispose();
    _maskController.dispose();
    super.dispose();
  }

  // Convert decimal number to 8-bit binary string
  String _intToBinary(int number) {
    return number.toRadixString(2).padLeft(8, '0');
  }

  // Convert IP address to binary notation
  String _ipToBinary(String ip) {
    List<String> parts = ip.split('.');
    return parts.map((part) => _intToBinary(int.parse(part))).join('.');
  }

  // Determine network class based on first octet
  String _getNetworkClass(List<int> ipOctets) {
    int firstOctet = ipOctets[0];
    if (firstOctet < 128) return 'Class A';
    if (firstOctet < 192) return 'Class B';
    if (firstOctet < 224) return 'Class C';
    if (firstOctet < 240) return 'Class D';
    return 'Class E';
  }

  // Generate additional network information
  Map<String, dynamic> _getAdditionalInfo(List<int> ipOctets, int mask) {
    return {
      'Default Gateway': '${ipOctets[0]}.${ipOctets[1]}.${ipOctets[2]}.1',
      'DHCP Range': '${ipOctets[0]}.${ipOctets[1]}.${ipOctets[2]}.100 - '
          '${ipOctets[0]}.${ipOctets[1]}.${ipOctets[2]}.200',
      'Reverse DNS': '${ipOctets[3]}.${ipOctets[2]}.${ipOctets[1]}'
          '.${ipOctets[0]}.in-addr.arpa',
      'Subnet Bits': mask,
      'Host Bits': 32 - mask,
      'RFC1918 Compliant': _isRFC1918Compliant(ipOctets) ? 'Yes' : 'No',
      'Multicast': _isMulticast(ipOctets) ? 'Yes' : 'No',
      'Broadcast Domain Size': pow(2, 32 - mask).toString(),
      'Network Capacity Utilization':
          '${(pow(2, 32 - mask) - 2) / pow(2, 32 - mask) * 100}%',
    };
  }

  // Check if IP address is RFC1918 compliant (private address)
  bool _isRFC1918Compliant(List<int> ipOctets) {
    return (ipOctets[0] == 10) ||
        (ipOctets[0] == 172 && ipOctets[1] >= 16 && ipOctets[1] <= 31) ||
        (ipOctets[0] == 192 && ipOctets[1] == 168);
  }

  // Check if IP address is in multicast range
  bool _isMulticast(List<int> ipOctets) {
    return ipOctets[0] >= 224 && ipOctets[0] <= 239;
  }

  // Determine network type (Private, Public, or Multicast)
  String _getNetworkType(List<int> ipOctets) {
    if (_isRFC1918Compliant(ipOctets)) return 'Private Internet';
    if (_isMulticast(ipOctets)) return 'Multicast';
    return 'Public Internet';
  }

  // Pad IP address string for aligned display
  String _padIP(String ip) {
    return ip.padRight(15);
  }

  // Copy calculation results to clipboard
  void _copyToClipboard(BuildContext context) {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results copied to clipboard')),
      );
    }
  }

  // Export network information as JSON
  void _exportAsJson() {
    if (_networkInfo != null) {
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(_networkInfo!.toJson());
      Clipboard.setData(ClipboardData(text: jsonString));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON exported to clipboard')),
      );
    }
  }

  // Main calculation function
  void _calculateNetwork() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _networkInfo = null;

      // Validate input fields
      if (_ipController.text.isEmpty || _maskController.text.isEmpty) {
        _hasError = true;
        _errorMessage = 'Please enter both IP address and subnet mask';
        return;
      }

      // Parse and validate IP address
      List<String> ipParts = _ipController.text.split('.');
      if (ipParts.length != 4) {
        _hasError = true;
        _errorMessage = 'Invalid IP address';
        return;
      }

      List<int> ipOctets = [];
      for (String part in ipParts) {
        try {
          int octet = int.parse(part);
          if (octet < 0 || octet > 255) {
            throw const FormatException();
          }
          ipOctets.add(octet);
        } catch (e) {
          _hasError = true;
          _errorMessage = 'Invalid IP address';
          return;
        }
      }

      // Parse and validate subnet mask
      int mask;
      try {
        mask = int.parse(_maskController.text);
        if (mask < 0 || mask > 32) {
          throw const FormatException();
        }
      } catch (e) {
        _hasError = true;
        _errorMessage = 'Invalid subnet mask (must be between 0 and 32)';
        return;
      }

      // Calculate network parameters
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

      // Convert results to string format
      String ipAddress = _ipController.text;
      String netmaskStr = _intToIp(fullMask);
      String wildcardStr = _intToIp(wildcard);
      String networkStr = _intToIp(networkInt);
      String broadcastStr = _intToIp(broadcastInt);
      String firstHostStr = _intToIp(firstHostInt);
      String lastHostStr = _intToIp(lastHostInt);

      // Calculate total usable hosts
      int totalHosts = mask == 32 ? 1 : (pow(2, (32 - mask)).toInt() - 2);

      // Get network classification and type
      String networkClass = _getNetworkClass(ipOctets);
      String networkType = _getNetworkType(ipOctets);
      Map<String, dynamic> additionalInfo = _getAdditionalInfo(ipOctets, mask);

      // Create NetworkInfo object with results
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
        networkType: networkType,
        binary: _ipToBinary(ipAddress),
        cidr: mask,
        additionalInfo: additionalInfo,
      );

      // Format results for display
      _result = '''
Address:   ${_padIP(ipAddress)}${_ipToBinary(ipAddress)}
Netmask:   ${_padIP(netmaskStr)} = $mask  ${_ipToBinary(netmaskStr)}
Wildcard:  ${_padIP(wildcardStr)}${_ipToBinary(wildcardStr)}
=>
Network:   ${_padIP('$networkStr/$mask')}${_ipToBinary(networkStr)}  ($networkClass)
Broadcast: ${_padIP(broadcastStr)}${_ipToBinary(broadcastStr)}
HostMin:   ${_padIP(firstHostStr)}${_ipToBinary(firstHostStr)}
HostMax:   ${_padIP(lastHostStr)}${_ipToBinary(lastHostStr)}
Hosts/Net: $totalHosts                     ($networkType)

Additional Network Information:
-----------------------------
Default Gateway: ${additionalInfo['Default Gateway']}
DHCP Range: ${additionalInfo['DHCP Range']}
Reverse DNS: ${additionalInfo['Reverse DNS']}
Subnet Bits: ${additionalInfo['Subnet Bits']}
Host Bits: ${additionalInfo['Host Bits']}
RFC1918 Compliant: ${additionalInfo['RFC1918 Compliant']}
Multicast: ${additionalInfo['Multicast']}
Broadcast Domain Size: ${additionalInfo['Broadcast Domain Size']}
Network Capacity Utilization: ${additionalInfo['Network Capacity Utilization']}''';
    });
  }

  // Convert integer to IP address string
  String _intToIp(int ipInt) {
    return '${(ipInt >> 24) & 255}.'
        '${(ipInt >> 16) & 255}.'
        '${(ipInt >> 8) & 255}.'
        '${ipInt & 255}';
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
            // Input card with IP and subnet mask fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        hintText: 'e.g., 192.168.1.1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maskController,
                      decoration: const InputDecoration(
                        labelText: 'Subnet Mask (CIDR)',
                        hintText: 'e.g., 24',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.filter_list),
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
            // Error message display
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
            // Results display area
            if (!_hasError && _result.isNotEmpty)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Copy and Export buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
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
                        const Divider(),
                        // Calculation results display
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
    );
  }
}
