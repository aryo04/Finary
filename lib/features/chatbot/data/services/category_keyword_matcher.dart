/// Helper dictionary & matcher for offline category detection.
class CategoryKeywordMatcher {
  CategoryKeywordMatcher._();

  static String detect(String itemName) {
    final lower = itemName.toLowerCase();

    // 1. Investasi & Profit & Cuan (Pemasukan)
    if (lower.contains('investasi') ||
        lower.contains('bitcoin') ||
        lower.contains('btc') ||
        lower.contains('crypto') ||
        lower.contains('kripto') ||
        lower.contains('saham') ||
        lower.contains('reksadana') ||
        lower.contains('dividen') ||
        lower.contains('profit') ||
        lower.contains('cuan') ||
        lower.contains('untung') ||
        lower.contains('trading') ||
        lower.contains('yield') ||
        lower.contains('bunga')) {
      return 'Investasi';
    }

    // 2. Gaji (Pemasukan)
    if (lower.contains('gaji') ||
        lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('upah') ||
        lower.contains('honor')) {
      return 'Gaji';
    }

    // 3. Freelance (Pemasukan)
    if (lower.contains('freelance') ||
        lower.contains('proyek') ||
        lower.contains('project') ||
        lower.contains('jasa') ||
        lower.contains('desain') ||
        lower.contains('side job') ||
        lower.contains('side hustle')) {
      return 'Freelance';
    }

    // 4. Bonus & Hadiah (Pemasukan)
    if (lower.contains('bonus') ||
        lower.contains('hadiah') ||
        lower.contains('thr') ||
        lower.contains('angpao') ||
        lower.contains('cashback') ||
        lower.contains('giveaway') ||
        lower.contains('ortu') ||
        lower.contains('orang tua') ||
        lower.contains('dikirim') ||
        lower.contains('dikasih') ||
        lower.contains('saku') ||
        lower.contains('jajan ortu') ||
        lower.contains('ayah') ||
        lower.contains('ibu') ||
        lower.contains('mama') ||
        lower.contains('papa')) {
      return 'Bonus & Hadiah';
    }

    // 5. Makan & Minum (Pengeluaran)
    if (lower.contains('kopi') ||
        lower.contains('esteh') ||
        lower.contains('es teh') ||
        lower.contains('teh') ||
        lower.contains('makan') ||
        lower.contains('sarapan') ||
        lower.contains('dinner') ||
        lower.contains('lunch') ||
        lower.contains('nasi') ||
        lower.contains('minum') ||
        lower.contains('resto') ||
        lower.contains('cafe') ||
        lower.contains('kafe') ||
        lower.contains('snack') ||
        lower.contains('jajan') ||
        lower.contains('mie') ||
        lower.contains('bakso') ||
        lower.contains('geprek') ||
        lower.contains('ayam') ||
        lower.contains('sate') ||
        lower.contains('martabak') ||
        lower.contains('roti') ||
        lower.contains('boba') ||
        lower.contains('gorengan') ||
        lower.contains('jus') ||
        lower.contains('burger') ||
        lower.contains('pizza') ||
        lower.contains('seblak') ||
        lower.contains('soto') ||
        lower.contains('pecel')) {
      return 'Makan & Minum';
    }

    // 6. Transportasi (Pengeluaran)
    if (lower.contains('parkir') ||
        lower.contains('bensin') ||
        lower.contains('pertalite') ||
        lower.contains('pertamax') ||
        lower.contains('solar') ||
        lower.contains('ojol') ||
        lower.contains('grab') ||
        lower.contains('gojek') ||
        lower.contains('maxim') ||
        lower.contains('indrive') ||
        lower.contains('tol') ||
        lower.contains('service') ||
        lower.contains('servis') ||
        lower.contains('oli') ||
        lower.contains('cuci motor') ||
        lower.contains('cuci mobil') ||
        lower.contains('tambal ban') ||
        lower.contains('bus') ||
        lower.contains('kereta') ||
        lower.contains('krl') ||
        lower.contains('tiket')) {
      return 'Transportasi';
    }

    // 7. Tagihan & Utilitas (Pengeluaran)
    if (lower.contains('listrik') ||
        lower.contains('token') ||
        lower.contains('pdam') ||
        lower.contains('air') ||
        lower.contains('wifi') ||
        lower.contains('indihome') ||
        lower.contains('pulsa') ||
        lower.contains('kuota') ||
        lower.contains('sewa') ||
        lower.contains('kost') ||
        lower.contains('kosan') ||
        lower.contains('kontrakan') ||
        lower.contains('cicilan') ||
        lower.contains('bpjs')) {
      return 'Tagihan & Utilitas';
    }

    // 8. Kesehatan (Pengeluaran)
    if (lower.contains('obat') ||
        lower.contains('apotek') ||
        lower.contains('dokter') ||
        lower.contains('vitamin') ||
        lower.contains('klinik') ||
        lower.contains('rumah sakit') ||
        lower.contains('periksa')) {
      return 'Kesehatan';
    }

    // 9. Pendidikan (Pengeluaran)
    if (lower.contains('buku') ||
        lower.contains('kursus') ||
        lower.contains('spp') ||
        lower.contains('ukt') ||
        lower.contains('kuliah') ||
        lower.contains('les') ||
        lower.contains('fotokopi') ||
        lower.contains('alat tulis') ||
        lower.contains('pulpen')) {
      return 'Pendidikan';
    }

    // 10. Hiburan (Pengeluaran)
    if (lower.contains('nonton') ||
        lower.contains('bioskop') ||
        lower.contains('xxi') ||
        lower.contains('game') ||
        lower.contains('topup') ||
        lower.contains('diamond') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('wisata') ||
        lower.contains('liburan') ||
        lower.contains('karaoke')) {
      return 'Hiburan';
    }

    // 11. Belanja (Pengeluaran)
    if (lower.contains('baju') ||
        lower.contains('celana') ||
        lower.contains('sepatu') ||
        lower.contains('tas') ||
        lower.contains('skincare') ||
        lower.contains('makeup') ||
        lower.contains('shopee') ||
        lower.contains('tokopedia') ||
        lower.contains('indomaret') ||
        lower.contains('alfamart') ||
        lower.contains('sabun') ||
        lower.contains('shampo') ||
        lower.contains('deterjen') ||
        lower.contains('kipas') ||
        lower.contains('elektronik') ||
        lower.contains('lampu') ||
        lower.contains('kabel') ||
        lower.contains('perabot') ||
        lower.contains('meja') ||
        lower.contains('kursi') ||
        lower.contains('lemari') ||
        lower.contains('kasur') ||
        lower.contains('sprei') ||
        lower.contains('bantal') ||
        lower.contains('panci') ||
        lower.contains('wajan') ||
        lower.contains('dapur') ||
        lower.contains('tv') ||
        lower.contains('ac') ||
        lower.contains('blender') ||
        lower.contains('dispenser') ||
        lower.contains('belanja')) {
      return 'Belanja';
    }

    return 'Belanja';
  }
}
