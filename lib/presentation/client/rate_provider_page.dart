import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/rating_service.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/custom_popup.dart';

class RateProviderPage extends StatefulWidget {
  final String orderId;
  final String providerId;
  final String providerName;

  const RateProviderPage({
    Key? key,
    required this.orderId,
    required this.providerId,
    this.providerName = 'Provider',
  }) : super(key: key);

  @override
  State<RateProviderPage> createState() => _RateProviderPageState();
}

class _RateProviderPageState extends State<RateProviderPage> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _reviewController = TextEditingController();
  
  int _selectedRating = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRated();
  }

  Future<void> _checkIfAlreadyRated() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isRated = await _ratingService.checkIfRated(widget.orderId);
      
      if (isRated) {
        if (mounted) {
          // Already rated, show popup and go back
          await CustomPopup.showInfo(
            context: context,
            title: 'Sudah Dirating',
            message: 'Anda sudah memberikan rating untuk layanan ini sebelumnya.',
            onConfirm: () {
              context.pop();
            },
          );
        }
      }
    } catch (e) {
      print('Error checking rating: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      CustomPopup.showWarning(
        context: context,
        title: 'Rating Diperlukan',
        message: 'Silakan pilih rating bintang terlebih dahulu sebelum submit.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ratingService.createRating(
        orderId: widget.orderId,
        serviceProviderId: widget.providerId,
        rating: _selectedRating,
        review: _reviewController.text.trim().isEmpty 
            ? null 
            : _reviewController.text.trim(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        // Show popup berdasarkan rating yang diberikan
        await CustomPopup.showRatingSuccess(
          context: context,
          rating: _selectedRating,
          onConfirm: () {
            // Navigate back to home after popup closed
            context.go('/client-home');
          },
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        CustomPopup.showError(
          context: context,
          title: 'Gagal Submit Rating',
          message: 'Terjadi kesalahan saat menyimpan rating: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rate Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Provider Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provider Name
                  Text(
                    widget.providerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRating = starNumber;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starNumber <= _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 50,
                            color: starNumber <= _selectedRating
                                ? Colors.amber
                                : Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Rating Text
                  if (_selectedRating > 0)
                    Text(
                      _getRatingText(_selectedRating),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Review TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Write your review (optional)...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip Button
                  TextButton(
                    onPressed: () => context.go('/client-home'),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent! ⭐️⭐️⭐️⭐️⭐️';
      case 4:
        return 'Great! ⭐️⭐️⭐️⭐️';
      case 3:
        return 'Good ⭐️⭐️⭐️';
      case 2:
        return 'Fair ⭐️⭐️';
      case 1:
        return 'Poor ⭐️';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

