// lib/features/facility/widgets/facility_search_bar.dart
import 'package:flutter/material.dart';

class FacilitySearchBar extends StatefulWidget {
  const FacilitySearchBar({
    super.key,
    required this.onChanged,
    required this.onCleared,
    required this.onFilterPressed,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;
  final VoidCallback onFilterPressed;

  @override
  State<FacilitySearchBar> createState() => _FacilitySearchBarState();
}

class _FacilitySearchBarState extends State<FacilitySearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) {
                  setState(() {});
                  widget.onChanged(_);
                },
                decoration: InputDecoration(
                  hintText: 'Badminton, Pickleball…',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1C894E), size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(_controller.clear);
                            widget.onCleared();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C894E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              onPressed: widget.onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
