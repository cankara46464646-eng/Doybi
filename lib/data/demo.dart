import 'package:flutter/material.dart';

import 'models.dart';

/// İlk sürümdeki örnek restoranlar. Sunucu bağlanınca veritabanından gelecek.

const mahalleler = ['Yenişehir', 'Hayrullah', 'Kurtuluş', 'Mimar Sinan', 'Bağlarbaşı'];

const restaurants = [
  Restaurant(
    id: 'UD',
    name: 'Usta Dürüm Evi',
    initials: 'UD',
    color: Color(0xFFA8200A),
    ink: Colors.white,
    cuisine: 'Kebap & dürüm',
    rating: 4.8,
    zones: {'Yenişehir': Zone(200, 0, '20-30'), 'Hayrullah': Zone(200, 0, '25-35'), 'Kurtuluş': Zone(300, 30, '35-45')},
    cash: true,
    card: true,
    address: 'Yenişehir Mah. 12. Sk. No: 4',
    menu: [
      MenuItem('adana', 'Adana Dürüm', 320, 'Dürümler', desc: 'Acılı zırh kıyması, lavaş, soğan, sumak'),
      MenuItem('urfa', 'Urfa Dürüm', 300, 'Dürümler', desc: 'Acısız zırh kıyması'),
      MenuItem('tavuk', 'Tavuk Dürüm', 220, 'Dürümler', desc: 'Kekikli tavuk şiş'),
      MenuItem('tava', 'Maraş Tava', 480, 'Tava', desc: 'Kuzu eti, biber, domates'),
      MenuItem('ayran', 'Ayran', 40, 'İçecekler'),
      MenuItem('salgam', 'Şalgam', 40, 'İçecekler'),
    ],
  ),
  Restaurant(
    id: 'LD',
    name: 'Lahmacun Durağı',
    initials: 'LD',
    color: Color(0xFF1C1917),
    ink: Colors.white,
    cuisine: 'Pide & lahmacun',
    rating: 4.6,
    zones: {'Yenişehir': Zone(150, 15, '25-35'), 'Kurtuluş': Zone(150, 0, '15-25'), 'Bağlarbaşı': Zone(200, 20, '30-40')},
    cash: true,
    card: false,
    address: 'Kurtuluş Mah. 8. Sk. No: 22',
    menu: [
      MenuItem('kiymali', 'Kıymalı Lahmacun', 90, 'Lahmacun'),
      MenuItem('acili', 'Acılı Lahmacun', 95, 'Lahmacun'),
      MenuItem('kasarli', 'Kaşarlı Pide', 210, 'Pide'),
      MenuItem('kusbasi', 'Kuşbaşılı Pide', 260, 'Pide'),
      MenuItem('salgam', 'Şalgam', 40, 'İçecekler'),
    ],
  ),
  Restaurant(
    id: 'FP',
    name: 'Fırın Pide Salonu',
    initials: 'FP',
    color: Color(0xFFFFC53D),
    ink: Color(0xFF1C1917),
    cuisine: 'Pide',
    rating: 4.7,
    zones: {'Yenişehir': Zone(250, 20, '30-40'), 'Mimar Sinan': Zone(200, 0, '20-30'), 'Hayrullah': Zone(250, 20, '35-45')},
    cash: true,
    card: true,
    address: 'Mimar Sinan Mah. 5. Sk. No: 11',
    menu: [
      MenuItem('karisik', 'Karışık Pide', 280, 'Pide', desc: 'Kıyma, kaşar, sucuk'),
      MenuItem('yumurtali', 'Yumurtalı Kaşarlı Pide', 230, 'Pide'),
      MenuItem('ayran', 'Ayran', 40, 'İçecekler'),
    ],
  ),
  Restaurant(
    id: 'CK',
    name: 'Çiğköfte Köşesi',
    initials: 'ÇK',
    color: Color(0xFFF1EDEA),
    ink: Color(0xFF1C1917),
    cuisine: 'Çiğköfte',
    rating: 4.4,
    zones: {'Yenişehir': Zone(120, 10, '20-30'), 'Hayrullah': Zone(120, 0, '15-25')},
    cash: true,
    card: true,
    address: 'Hayrullah Mah. 3. Sk. No: 9',
    menu: [
      MenuItem('ckdurum', 'Çiğköfte Dürüm', 90, 'Dürümler', desc: 'Nar ekşili, yeşillikli'),
      MenuItem('ckporsiyon', 'Porsiyon Çiğköfte', 160, 'Porsiyon'),
      MenuItem('ayran', 'Ayran', 35, 'İçecekler'),
    ],
  ),
];
