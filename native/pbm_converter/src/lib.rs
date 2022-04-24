use rustler::Binary;

#[rustler::nif]
fn extract_pixels(pixels: Binary, width: usize, height: usize) -> Vec<u8> {
    let pixels = pixels.as_slice();
    let bytes_per_row = (width as f32 / 8.0).ceil() as usize;
    let mut new_bytes: Vec<u8> = Vec::with_capacity(width * height);

    for y in 0..height {
        for x in 0..width {
            let shift = 7 - x % 8;
            let byte = x / 8;
            let pixel = (pixels[y * bytes_per_row + byte] & (1 << shift)) >> shift;
            new_bytes.push(pixel);
        }
    }

    new_bytes
}

rustler::init!("Elixir.Mix.Tasks.ExtractPixels", [extract_pixels]);

// Attempt to write the whole parsing logic in rust. I've given up

// const INVALID_DATA_ERR: Result<(usize, usize, usize, Vec<Vec<Vec<u8>>>), String> =
//     Err("invalid data".to_owned());

// #[rustler::nif]
// fn extract_data(pixels: Binary) -> Result<(usize, usize, usize, Vec<Vec<Vec<u8>>>), String> {
//     let pixels = pixels.as_slice();
//     let space_index = find_index(pixels, ' ')?;
//     let new_line_index = find_index(&pixels[3..], '\n')?;

//     let width: usize =
//         std::str::from_utf8(&pixels[3..space_index]).map_or(INVALID_DATA_ERR, |str| str.parse())?;
//     let height: usize = pixels[space_index + 1..new_line_index].parse();
//     let chunk_size = height * (width / 8.0).ceil;

//     let header_size = 3 + new_line_index;
//     let frames = pixels.len() / (header_size + chunk_size);

//     let mut result = Vec::with_capacity(frames);
//     for frame in 0..frames {
//         let rows = Vec::with_capacity(height);
//         let mut current_byte = 0;

//         let current_position = (header_size + chunk_size) * frame;
//         let chunk = &pixels[current_position..current_position + chunk_size];

//         for y in 0..height {
//             let row = Vec::with_capacity(width);
//             for x in 0..width {
//                 if current_byte % 8 == 0 && current_byte != 0 {
//                     current_byte += 1;
//                 }

//                 let shift = x % 8;
//                 let pixel = (pixels[current_byte] & (1 << shift)) >> shift;
//                 row.push(pixel);
//             }
//             current_byte += 1;
//             rows.push(row);
//         }
//         result.push(rows);
//     }

//     Ok((frames, height, width, result))
// }

// fn find_index(bytes: &[u8], char: char) -> Result<usize, String> {
//     bytes
//         .iter()
//         .enumerate()
//         .find(|(_index, byte)| **byte as char == char)
//         .map_or(Err("Invalid data".to_owned()), |(index, _)| Ok(index))
// }
