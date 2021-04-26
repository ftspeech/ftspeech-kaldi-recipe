import sys
import os
import argparse
import locale




# set locale for sorting purposes
locale.setlocale(locale.LC_ALL, "C")


def get_spk_rec_utt_id(utt_id):
    split_utt = utt_id.split('_')
    spk_id = split_utt[0]
    rec_id = '_'.join(split_utt[1:3])
    new_utt_id = spk_id + '-' + '_'.join(split_utt[1:])

    return spk_id, rec_id, new_utt_id


def format_wscp(rec_id, audio_dir, kaldi_dir):
# extended filename: <kaldi dir>/tools/sph2pipe_v2.5/sph2pipe -f wav -p -c 1 <full path to rec> |
    rec_filepath = f'{audio_dir}/{rec_id[:4]}/{rec_id}.wav'

    #return f'{rec_id} {kaldi_dir}/tools/sph2pipe_v2.5/sph2pipe -f wav -p -c 1 {rec_filepath} |'
    return f'{rec_id} {rec_filepath}'


def make_kaldi_files(in_file, out_dir, kaldi_dir):
    audio_data_dir = '/'.join(in_file.split('/')[:-2]) + '/audio'

    text = []  # file format: <utt_id> <utt_transcript>
    segs = []  # file format: <utt_id> <rec_id> <seg_start> <seg_end>
    u2s = []   # file format: <utt_id> <spk_id>
    wscp = set()  # file format: <rec_id> <extended_filename>

    with open(in_file, encoding='utf8') as infile:
        infile.readline()
        for line in infile:
            utt_id, _, start, end, transcript = line.strip().split('\t')
            spk, rec, new_utt_id = get_spk_rec_utt_id(utt_id)
            rec_wscp = format_wscp(rec, audio_data_dir, kaldi_dir)

            text.append(' '.join([new_utt_id, transcript]))
            segs.append(' '.join([new_utt_id, rec, start, end]))
            u2s.append(' '.join([new_utt_id, spk]))
            wscp.add(rec_wscp)
        
    wscp = list(wscp)
    text.sort(key=locale.strxfrm)
    segs.sort(key=locale.strxfrm)
    u2s.sort(key=locale.strxfrm)
    wscp.sort(key=locale.strxfrm)


    with open(f'{out_dir}/text', 'w+', encoding='utf8') as textf:
        # file format: <utt_id> <utt_transcript>
        textf.write('\n'.join(text))
        textf.write('\n')

    with open(f'{out_dir}/segments', 'w+', encoding='utf8') as segf:
        # file format: <utt_id> <rec_id> <seg_start> <seg_end>
        segf.write('\n'.join(segs))
        segf.write('\n')

    with open(f'{out_dir}/utt2spk', 'w+', encoding='utf8') as u2sf:
        # file format: <utt_id> <spk_id>
        u2sf.write('\n'.join(u2s))
        u2sf.write('\n')
    
    with open(f'{out_dir}/wav.scp', 'w+', encoding='utf8') as wscpf:
        # file format: <rec_id> <extended_filename>
        # extended filename: <kaldi dir>/tools/sph2pipe_v2.5/sph2pipe -f wav -p -c 1 <full path to rec> |
        wscpf.write('\n'.join(wscp))
        wscpf.write('\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # specify input tsv file and output directory as command line arguments
    # usage: python data_prep.py [-h] -i INPUT_FILE -o OUTPUT_DIR
    parser.add_argument("-i", "--input_file", dest="input_file", help="Text file containing the textual transcripts of the input data.")
    parser.add_argument("-o", "--output_dir", dest="output_dir", help="Directory in which to store the text files required by Kaldi.")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    kaldi_dir = os.environ['KALDI_ROOT']
    make_kaldi_files(args.input_file, args.output_dir, kaldi_dir)
