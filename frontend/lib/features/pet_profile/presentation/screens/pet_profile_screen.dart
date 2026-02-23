import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../design_system/components/button.dart';
import '../../../../core/constants/pet_constants.dart';
import '../controllers/pet_profile_controller.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

class PetProfileScreen extends ConsumerStatefulWidget {
  const PetProfileScreen({super.key});

  @override
  ConsumerState<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends ConsumerState<PetProfileScreen> {
  String? _selectedBreed;
  String? _selectedWeight;
  String? _selectedAgeStage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(petProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            AppLocalizations.of(context)!.petProfile_title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.petProfile_enterInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedBreed,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.petProfile_breed,
                  border: const OutlineInputBorder(),
                ),
                items: PetConstants.breeds.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBreed = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWeight,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.petProfile_weight,
                  border: const OutlineInputBorder(),
                ),
                items: PetConstants.weightBuckets.map((weight) {
                  return DropdownMenuItem(
                    value: weight,
                    child: Text(weight),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWeight = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAgeStage,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.petProfile_ageStage,
                  border: const OutlineInputBorder(),
                ),
                items: PetConstants.ageStages.map((stage) {
                  return DropdownMenuItem(
                    value: stage,
                    child: Text(stage),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAgeStage = value;
                  });
                },
              ),
              const Spacer(),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              PrimaryButton(
                text: AppLocalizations.of(context)!.petProfile_save,
                isLoading: state.isLoading,
                onPressed: (_selectedBreed != null &&
                        _selectedWeight != null &&
                        _selectedAgeStage != null)
                    ? () async {
                        await ref.read(petProfileControllerProvider.notifier).createPet(
                              breedCode: _selectedBreed!,
                              weightBucket: _selectedWeight!,
                              ageStage: _selectedAgeStage!,
                            );

                        // createPet 완료 후 최신 상태 확인
                        final currentState = ref.read(petProfileControllerProvider);
                        if (mounted && currentState.error == null && currentState.petId != null) {
                          context.go(RouteNames.home);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
