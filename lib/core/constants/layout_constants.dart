import 'package:flutter/widgets.dart';

/// Hauteur utile de la rangée d’icônes du shell principal (hors [SafeArea] système).
const double kOklMainNavContentHeight = 62;

/// Hauteur totale sous laquelle la barre d’onglets du [MainShell] recouvre le corps
/// ([Scaffold.extendBody] + [SafeArea] bas de la barre).
double oklMainShellBottomOverlay(BuildContext context) =>
    kOklMainNavContentHeight + MediaQuery.viewPaddingOf(context).bottom;

/// Padding bas pour listes / défilement dans les onglets du shell.
double oklMainShellListBottomPadding(BuildContext context, {double gap = 12}) =>
    oklMainShellBottomOverlay(context) + gap;
