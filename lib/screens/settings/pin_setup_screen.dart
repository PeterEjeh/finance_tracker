import 'package:flutter/material.dart';
import '../../services/pin_auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinAuthService _pinService = PinAuthService();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isSettingPin = false;
  bool _isConfirming = false;
  bool _pinAlreadyExists = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final status = await _pinService.getPinStatus();
    if (status.isSet) {
      setState(() {
        _pinAlreadyExists = true;
        _isConfirming = true;
      });
    }
  }

  void _onPinChanged(String value) {
    setState(() {
      if (_isConfirming) {
        _confirmPin = value;
      } else {
        _enteredPin = value;
      }
      _errorMessage = null;
    });

    if (value.length == 4) {
      if (_isConfirming) {
        _verifyAndUpdatePin();
      } else {
        setState(() {
          _isConfirming = true;
        });
      }
    }
  }

  Future<void> _verifyAndUpdatePin() async {
    if (_isSettingPin) return;

    setState(() {
      _isSettingPin = true;
    });

    try {
      if (_confirmPin == _enteredPin) {
        final success = await _pinService.setPin(_confirmPin);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN set successfully!')),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to set PIN. Please try again.';
            _resetPinEntry();
          });
        }
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _resetPinEntry();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error setting PIN. Please try again.';
        _resetPinEntry();
      });
    } finally {
      setState(() {
        _isSettingPin = false;
      });
    }
  }

  void _resetPinEntry() {
    setState(() {
      _enteredPin = '';
      _confirmPin = '';
      _isConfirming = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      }
      _errorMessage = null;
    });
  }

  Widget _buildPinDot(int index, String pin, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < pin.length
            ? theme.primaryColor
            : (isDark ? Colors.grey[600] : Colors.grey[300]),
      ),
    );
  }

  Widget _buildNumberButton(String number, ThemeData theme) {
    return InkWell(
      onTap: _isSettingPin
          ? null
          : () => _onPinChanged(
              _isConfirming ? _confirmPin + number : _enteredPin + number,
            ),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Set PIN',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.textTheme.titleLarge?.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirming
                    ? (_pinAlreadyExists ? 'Update PIN' : 'Confirm PIN')
                    : 'Enter New PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? (_pinAlreadyExists
                          ? 'Enter your new PIN to update'
                          : 'Enter your PIN again to confirm')
                    : 'Enter a 4-digit PIN for app access',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildPinDot(
                    index,
                    _isConfirming ? _confirmPin : _enteredPin,
                    theme,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Loading indicator
              if (_isSettingPin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),

              // Number pad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildNumberButton('1', theme),
                    _buildNumberButton('2', theme),
                    _buildNumberButton('3', theme),
                    _buildNumberButton('4', theme),
                    _buildNumberButton('5', theme),
                    _buildNumberButton('6', theme),
                    _buildNumberButton('7', theme),
                    _buildNumberButton('8', theme),
                    _buildNumberButton('9', theme),
                    const SizedBox(), // Empty space
                    _buildNumberButton('0', theme),
                    // Backspace button
                    InkWell(
                      onTap: _onBackspace,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 24,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
