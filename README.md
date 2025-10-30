



# Pokémon FireRed Lua Scripts
## Giới thiệu

Các script này dành cho giả lập mGBA, chỉ dùng để đọc thông tin từ game (KHÔNG chỉnh sửa, hack hay ảnh hưởng đến dữ liệu game).

## Tính năng chính

- **main_pkm.lua**: Script tổng, dùng để gọi và kết hợp các script phụ (check_all_party.lua, walk_pkm.lua). Dễ dàng mở rộng, thêm tính năng mới.
- **check_all_party.lua**: Hiển thị thông tin chi tiết toàn bộ Pokémon trong party (chỉ số, nature, item, IVs, EVs, moves, abilities, type, điểm yếu, kháng, miễn nhiễm).
- **walk_pkm.lua**: Tự động phát hiện Pokémon hoang dã/trainer khi gặp battle, hiển thị thông tin chi tiết (chỉ số, IVs, EVs, moves, abilities,...).

### Tính năng 

- **Kiểm tra Moves**: Hiển thị tên, PP, và danh sách move của từng Pokémon.
- **Kiểm tra Abilities**: Hiển thị abilities, mô tả hiệu ứng của từng Pokémon.
- **Hiển thị IV/EV**: Đọc và so sánh IV gốc, EV từng chỉ số, xếp hạng IV tổng.
- **Hiển thị Type, Điểm yếu, Kháng, Miễn nhiễm**: Phân tích type, điểm yếu, kháng, miễn nhiễm.
- **Tự động cập nhật thông tin khi party/battle thay đổi.**
- **Không can thiệp, không thay đổi dữ liệu game.**

## Hướng dẫn

1. Mở mGBA, vào menu Lua Scripting, load script main_pkm.lua.
2. Thông tin sẽ hiển thị ở console hoặc buffer riêng (Party Info, Competitor Info).
3. Có thể chỉnh sửa, mở rộng script để thêm tính năng mới.

## Lưu ý

- Chỉ hoạt động trên mGBA có Lua scripting.
- Dùng cho mục đích tra cứu, săn IV/nature đẹp, nghiên cứu mechanics.
- Không dùng cho cheat/hack.

---

# Pokémon FireRed Lua Scripts

## Overview

These scripts are designed for the mGBA emulator and only read information from the game. They do not modify, affect, or hack the game in any way.

## Main Features

- **main_pkm.lua**: Central script to load and combine other scripts (check_all_party.lua, walk_pkm.lua). Easy to extend and add new features.
- **check_all_party.lua**: Shows detailed info for all Pokémon in your party (stats, nature, held item, IVs, EVs, moves, abilities, types, weaknesses, resistances, immunities).
- **walk_pkm.lua**: Automatically detects wild Pokémon and trainer battles, displays full info (stats, IVs, EVs, moves, abilities, etc.).

### Features

- **Check Moves**: Shows move names, PP, and move list for each Pokémon.
- **Check Abilities**: Shows ability names and descriptions for each Pokémon.
- **Show IV/EV**: Reads and compares original IVs, shows EVs for each stat, ranks total IVs.
- **Show Type, Weakness, Resistance, Immunity**: Analyzes type, weaknesses, resistances, immunities.
- **Auto-update info when party or battle changes.**
- **No game data modification.**

## Usage

1. Open mGBA, go to Lua Scripting menu, load main_pkm.lua.
2. Info will be shown in console or buffer (Party Info, Competitor Info).
3. You can edit/extend scripts to add new features.

## Notes

- Only works in mGBA with Lua scripting enabled.
- For information, hunting IV/nature, and research purposes.
- Not for cheating/hacking.




