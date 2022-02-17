for file in `find /home/jianghao/Dataset/4k_video_test/crop_videos/ | grep ".*mp4"`
do
    echo $(basename $file .mp4)
    tmppath="/home/jianghao/Code/Graduation/PreProcess/videos/"
    echo $tmppath$(basename $file .mp4)
    mkdir $tmppath$(basename $file .mp4)
    /home/jianghao/opt/ffmpeg/bin/ffmpeg -i $file -pix_fmt yuv420p -frames 100 decode.yuv -y # > /dev/null 2>&1

    /home/jianghao/anaconda3/envs/pytorch/bin/python /home/jianghao/Code/Graduation/PreProcess/codes/test_forward_yuv.py \
    -opt /home/jianghao/Code/Graduation/PreProcess/codes/options/test/test_EDSR_forward.yml #  > /dev/null 2>&1
	for qp in {23..27..1}
	do
		/home/jianghao/opt/ffmpeg/bin/ffmpeg -s 1920x1056 -pix_fmt yuv420p -i decode_net.yuv \
		-c:v libx265 -x265-params "qp=${qp}" transcode_net.hevc -y > $tmppath$(basename $file .mp4)/transcode_net_${qp} 2>&1

		/home/jianghao/opt/ffmpeg/bin/ffmpeg  -s 3840x2112 -pix_fmt yuv420p -i decode.yuv -i transcode_net.hevc \
		-filter_complex "[1:v]scale=3840x2112:flags=bicubic[scale];[scale][0:v]psnr=stats_file="$tmppath$(basename $file .mp4)/psnr_net_${qp} \
		-f null /dev/null > $tmppath$(basename $file .mp4)/Avg_psnr_net_${qp} 2>&1
		/home/jianghao/opt/ffmpeg/bin/ffmpeg  -s 3840x2112 -pix_fmt yuv420p -i decode.yuv -i transcode_net.hevc \
		-filter_complex "[1:v]scale=3840x2112:flags=bicubic[scale];[scale][0:v]ssim=stats_file="$tmppath$(basename $file .mp4)/ssim_net_${qp} \
		-f null /dev/null > $tmppath$(basename $file .mp4)/Avg_ssim_net_${qp} 2>&1

		/home/jianghao/opt/ffmpeg/bin/ffmpeg -s 3840x2112 -pix_fmt yuv420p -i decode.yuv -pix_fmt yuv420p -s 1920x1056 -sws_flags lanczos \
		-c:v libx265 -x265-params "qp=${qp}" transcode_lanczos.hevc -y > $tmppath$(basename $file .mp4)/transcode_lanczos_${qp} 2>&1

		/home/jianghao/opt/ffmpeg/bin/ffmpeg  -s 3840x2112 -pix_fmt yuv420p -i decode.yuv -i transcode_lanczos.hevc \
		-filter_complex "[1:v]scale=3840x2112:flags=bicubic[scale];[scale][0:v]psnr=stats_file="$tmppath$(basename $file .mp4)/psnr_lanczos_${qp} \
		-f null /dev/null > $tmppath$(basename $file .mp4)/Avg_psnr_lanczos_${qp} 2>&1
		/home/jianghao/opt/ffmpeg/bin/ffmpeg  -s 3840x2112 -pix_fmt yuv420p -i decode.yuv -i transcode_lanczos.hevc \
		-filter_complex "[1:v]scale=3840x2112:flags=bicubic[scale];[scale][0:v]ssim=stats_file="$tmppath$(basename $file .mp4)/ssim_lanczos_${qp} \
		-f null /dev/null > $tmppath$(basename $file .mp4)/Avg_ssim_lanczos_${qp} 2>&1
	done
	python BD-rate.py -path $tmppath$(basename $file .mp4) >> BD-Rate-YUV-47500.log
done